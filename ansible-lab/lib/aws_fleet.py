"""The cloud team's EC2 API, as used by the labs' setup/verify scripts (runs in the controller with boto3).

The fake AWS (moto) honours PrivateIpAddress, so an instance "web1" launched with web1's lab IP *is* web1:
the EC2 inventory then resolves to a machine Ansible can reach over SSH.

usage (piped into python3 by `aws` in lib/ans.sh):
  launch <name> <node|ip> <role> [env=prod] [region]   one instance, tags Name/Role/Env (+Team=shop);
                                                        idempotent: an existing stopped one is started
  start|stop|terminate <name> [region]
  list [region]                                         name state private-ip public-dns
(moto can't reuse the private IP of a terminated instance - scenarios stop/start instead of re-launching)
"""
import sys

import boto3

NODE_IPS = {"lb1": "10.78.0.10", "web1": "10.78.0.11", "web2": "10.78.0.12", "web3": "10.78.0.13",
            "app1": "10.78.0.14", "app2": "10.78.0.15", "db1": "10.78.0.21", "test1": "10.78.0.31"}


def ec2(region):
    return boto3.client("ec2", region_name=region)


def subnet(c):
    """The VPC 10.78.0.0/16 with subnet 10.78.0.0/24 (= the lab network), created on first use."""
    vpcs = c.describe_vpcs(Filters=[{"Name": "tag:Name", "Values": ["acme-prod"]}])["Vpcs"]
    if vpcs:
        vpc = vpcs[0]["VpcId"]
    else:
        vpc = c.create_vpc(CidrBlock="10.78.0.0/16", TagSpecifications=[
            {"ResourceType": "vpc", "Tags": [{"Key": "Name", "Value": "acme-prod"}]}])["Vpc"]["VpcId"]
    subs = c.describe_subnets(Filters=[{"Name": "vpc-id", "Values": [vpc]}])["Subnets"]
    if subs:
        return subs[0]["SubnetId"]
    return c.create_subnet(VpcId=vpc, CidrBlock="10.78.0.0/24")["Subnet"]["SubnetId"]


def find(c, name, required=True):
    res = c.describe_instances(Filters=[{"Name": "tag:Name", "Values": [name]},
                                        {"Name": "instance-state-name", "Values": ["pending", "running", "stopped"]}])
    ids = [i["InstanceId"] for r in res["Reservations"] for i in r["Instances"]]
    if not ids and required:
        sys.exit(f"no live instance named {name}")
    return ids


def launch(name, node, role, env="prod", region="eu-west-1"):
    c = ec2(region)
    if find(c, name, required=False):
        start(name, region)
        return
    ip = NODE_IPS.get(node, node)
    ami = c.describe_images(Owners=["amazon"])["Images"][0]["ImageId"]
    tags = [{"Key": "Name", "Value": name}, {"Key": "Role", "Value": role}, {"Key": "Env", "Value": env},
            {"Key": "Team", "Value": "shop"}]
    i = c.run_instances(ImageId=ami, MinCount=1, MaxCount=1, InstanceType="t3.small",
                        NetworkInterfaces=[{"DeviceIndex": 0, "SubnetId": subnet(c), "PrivateIpAddress": ip,
                                            "AssociatePublicIpAddress": True}],
                        TagSpecifications=[{"ResourceType": "instance", "Tags": tags}])["Instances"][0]
    print(name, i["InstanceId"], i["PrivateIpAddress"], i.get("PublicDnsName", ""))


def start(name, region="eu-west-1"):
    c = ec2(region)
    c.start_instances(InstanceIds=find(c, name))
    print(name, "started")


def stop(name, region="eu-west-1"):
    c = ec2(region)
    c.stop_instances(InstanceIds=find(c, name))


def terminate(name, region="eu-west-1"):
    c = ec2(region)
    c.terminate_instances(InstanceIds=find(c, name))


def list_(region="eu-west-1"):
    for r in ec2(region).describe_instances()["Reservations"]:
        for i in r["Instances"]:
            name = next((t["Value"] for t in i.get("Tags", []) if t["Key"] == "Name"), "-")
            print(name, i["State"]["Name"], i.get("PrivateIpAddress", "-"), i.get("PublicDnsName", "-") or "-")


if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    {"launch": launch, "start": start, "stop": stop, "terminate": terminate, "list": list_}[cmd](*args)
