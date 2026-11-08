# DevOps Troubleshooting Labs

Break/fix labs for Linux, Docker Swarm, Terraform/Terragrunt and Ansible that run offline, on one machine.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Platform: Linux x86_64](https://img.shields.io/badge/platform-Linux%20x86__64-lightgrey)
![Runs on Docker](https://img.shields.io/badge/runs%20on-Docker-2496ED)
![Shell: Bash](https://img.shields.io/badge/shell-bash-4EAA25)

Hands-on troubleshooting practice for DevOps and SRE work. Each scenario breaks a real system on
purpose, following failure patterns that come up in interviews and real postmortems. It gives you
only what you would get on call: a ticket with symptoms and a definition of done. You investigate
with real tools in a real shell, fix the problem the way you would in production, and `./lab verify`
checks the result automatically. There are 130 incidents across four labs, plus guided learn tracks
for Terraform/Terragrunt (14 labs) and Ansible (16 labs). Everything runs locally in Docker: no cloud
account, no root on the host, and no internet after the first build. Use it for interview preparation,
on-call drills or teaching.

## Contents

- [Labs](#labs)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Installation and quick start](#installation-and-quick-start)
- [Safety and isolation](#safety-and-isolation)
- [Cleanup](#cleanup)
- [Repository layout](#repository-layout)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Labs

| Lab | What you practise | Scenarios | Runs as |
|---|---|---|---|
| [linux-lab](linux-lab/README.md) | Processes, zombies, OOM killer, open-file limits, disk full and inodes, `chattr`, mounts and mount options, permissions, sshd, sudoers, systemd units, cron, ports in use, shared libraries, DNS and resolver, bind address and iptables, TLS, log forensics, plus one multi-fault "boss fight" | 26 | Throwaway Debian 12 servers with real systemd (unprivileged containers) |
| [swarm-lab](swarm-lab/README.md) | Scheduling and placement, images, secrets, overlay networking and DNS, healthchecks, cgroups and exit 137, filesystems, signals, firewalls, MTU, `tc`/netem, routing, Raft quorum loss, plus a chaos mode for your own faults | 20 | A 3-node Docker Swarm in which every node is a Docker-in-Docker "VM" |
| [terra-labs](terra-labs/README.md) | Terraform 1.17 and Terragrunt 1.2: state, locking and backends, refactors and `moved`, drift, `for_each`, modules and versions, provider lock files, Stacks, dependencies and mocks, `terraform test`, secrets in state, pipelines | 14 learn + 37 incidents | Pinned Terraform/Terragrunt against a local fake AWS ([moto](https://github.com/getmoto/moto)) and a local git module registry |
| [ansible-lab](ansible-lab/README.md) | ansible-core 2.22: inventories and connections, variable precedence, the 2.19+ templating changes, roles and pinned collections, handlers, rolling deploys (`serial`, canaries, `max_fail_percentage`, `throttle`, `strategy: free`), vault and 2.22 secret masking, ansible-lint, molecule, execution environments, Event-Driven Ansible, the `aws_ec2` inventory, `ansible-test sanity` | 16 learn + 47 incidents | A controller container plus Debian 12 and Rocky 9 nodes with real systemd and sshd (unprivileged), an offline package mirror, a fake AWS (moto) and an EDA activation (ansible-rulebook) |

Each lab is self-contained, with its own CLI, containers, network and state. Its README has the
full scenario list.

## How it works

All labs share the same `./lab` command-line tool:

```bash
cd <lab>
./lab build            # once: build images / download pinned tools (swarm-lab: ./lab up)
./lab list             # scenarios, ✔ = solved before
./lab start <id>       # fresh environment, broken on purpose, prints the ticket
./lab sh               # shell where the problem is
./lab verify           # PASS / FAIL against the ticket's test
./lab hint             # progressive hints; ./lab solution when stuck, ./lab solve to see the fix
./lab stop             # throw it all away (swarm-lab: ./lab reset or ./lab destroy)
```

- `./lab start random` hides which scenario you got, which is good interview practice.
- `./lab help` lists each lab's extra commands:
  - linux-lab: `ssh`
  - swarm-lab: `deploy`, `inject`/`clear` (chaos mode)
  - terra-labs: `env`, `diff`, `doctor`, `up`/`down`
  - ansible-lab: `ssh`/`node`, `run`, `diff`, `doctor`, `ee` (execution environments), `eda` (the
    rulebook activation), `interview` (three random incidents against the clock, scored), `up`/`down`
- `./lab selftest <id|all>` proves that a scenario fails after setup and passes after the reference fix.

**Rules of the game**
- The ticket's **Test** line ("Done when" in swarm-lab) defines "fixed". The checks also catch
  shortcuts, such as restarting instead of fixing or deleting state.
- Don't read `scenarios/*/.lab/` or `learn/*/.lab/`: they hold the setup, the checks and the
  reference solution. `terra-labs/docs/CATALOG.md` and `ansible-lab/docs/CATALOG.md` list every root
  cause, so they are spoilers too.
- `./lab start` always rebuilds from scratch, so you can't break anything permanently.

## Requirements

**All labs**

- A Linux x86_64 host; a VM is fine and recommended (see [Safety](#safety-and-isolation)).
  Tested on Ubuntu 22.04 with kernel 6.5 and cgroup v2.
- Docker Engine with cgroup v2, tested with 29.1. Your user must be able to run `docker` without
  `sudo` (member of the `docker` group). The `docker compose` plugin is **not** required.
- Bash 4 or newer, GNU coreutils, `sed`, `awk`, and `git` to clone the repo.
- Internet access for the first build of each lab. After that, the labs work offline.
- No root or `sudo` on the host.

**Per lab**

| | linux-lab | swarm-lab | terra-labs | ansible-lab |
|---|---|---|---|---|
| Extra host tools | `ssh`, `ssh-keygen` (only for `./lab ssh`) | `curl` | `git`, `curl`, `unzip`, `jq`, `python3`, AWS CLI v2 | `git`, `jq`, `python3` (+ PyYAML), `curl`, `ssh-keygen` |
| Disk | ~1 GB | ~2 GB | ~2.5 GB | ~4 GB |
| RAM | ~300 MB per running scenario | ~2 GB | No figure given; runs moto plus a few small containers | ~2-2.5 GB for the biggest labs |
| Must be free | Docker subnet `10.77.0.0/24` | Docker subnet `172.30.0.0/24` | `127.0.0.1:4566` | Docker subnet `10.78.0.0/24` |
| First run | `./lab build`, ~1-2 min: builds `linuxlab/server:1` | `./lab up`, ~1 min: builds the node image, pulls 5 base images | `./lab build`, ~2 min, ~0.5 GB: Terraform, Terragrunt, TFLint, provider mirror, moto image | `./lab build`, ~1.5 GB once: controller, node, EE and moto images, apt/dnf mirror, collections, Python wheelhouses |
| Container privileges | Unprivileged, selected capabilities | **Privileged** (Docker-in-Docker) | Unprivileged | Unprivileged (nodes: `SYS_ADMIN`, seccomp/AppArmor unconfined for systemd) |

Tool versions in terra-labs are pinned in [`terra-labs/versions.env`](terra-labs/versions.env):
Terraform 1.17.1, Terragrunt 1.2.1, TFLint 0.65.0, moto 5.2.5 and nine mirrored providers. The
downloads are verified against sha256 checksums. A `terraform` already installed on the host is ignored.
ansible-lab pins its tools in [`ansible-lab/versions.env`](ansible-lab/versions.env): ansible-core 2.22.0,
ansible-lint and molecule 26.11, ansible-rulebook 1.3.2, moto 5.2.5 and every collection version. An `ansible`
already installed on the host is ignored; everything runs in the lab's controller container.

## Installation and quick start

```bash
git clone https://github.com/<owner>/<repo>.git
cd <repo>
```

**linux-lab**: Linux server troubleshooting

```bash
cd linux-lab
./lab build          # once
./lab start 01       # prints the ticket
./lab sh             # you are "admin" with sudo on the broken server
./lab verify
```

**swarm-lab**: Docker Swarm incidents

```bash
cd swarm-lab
./lab up             # ~1 min the first time: 3 nodes, swarm, registry
./lab start 01
./lab sh manager1    # also: worker1, worker2
./lab verify
```

**terra-labs**: Terraform and Terragrunt

```bash
cd terra-labs
./lab build          # once
./lab doctor         # checks versions, Docker, moto and disk
./lab start L01      # learn track; incidents start with a letter code, e.g. ./lab start S01
./lab sh             # terraform, terragrunt and aws, wired to the fake AWS
./lab verify         # judged on a fresh "CI checkout" of workspace/
```

To use your own shell or IDE with terra-labs, run `eval "$(./lab env)"` from `terra-labs/`.

**ansible-lab**: Ansible (ansible-core 2.22)

```bash
cd ansible-lab
./lab build          # once
./lab start L01      # learn track; incidents start with a letter code, e.g. ./lab start T01
./lab sh             # shell in the controller at /work (= workspace/): ansible-playbook, ansible-lint, ...
./lab verify         # judged on a fresh "CI checkout" of workspace/, with probes on the nodes
./lab interview      # three random incidents against the clock, scored at the end
```

## Safety and isolation

- **linux-lab**: The containers are not privileged. They get no host devices, read-only `/proc/sys`
  and `/sys`, and only the capabilities scenarios need (`SYS_ADMIN`, `NET_ADMIN`, `SYS_PTRACE`,
  `LINUX_IMMUTABLE`). systemd units that touch the host are masked, and no scenario throttles a real disk.
- **swarm-lab**: ⚠️ **Each node is a privileged Docker-in-Docker container**, with its own `dockerd`,
  iptables, `tc` and routes. Privileged containers share the host kernel and can affect it, so run
  this lab inside a VM you can afford to reboot. On the host it creates only containers, one bridge
  network, volumes and two images.
- **terra-labs**: Nothing runs privileged, and moto listens on `127.0.0.1` only. Real AWS is
  unreachable by design:
  - the access keys are dummies,
  - every AWS endpoint points to `http://localhost:4566`,
  - AWS profiles are unset, and the AWS config lives in the lab's own `.state/aws/`.

  `~/.aws`, `~/.terraformrc` and `~/.gitconfig` are never read. Everything the lab creates in Docker
  is named `tfl-*` and labelled `terralab.scenario`.
- **ansible-lab**: Nothing runs privileged and no lab container gets the Docker socket. The nodes get
  `SYS_ADMIN` and unconfined seccomp/AppArmor so systemd can run, plus 384 MB RAM and 1 CPU each. The lab
  network `10.78.0.0/24` is `--internal`, so nothing on it can reach the internet or your LAN, and no port
  is published on the host. The fake AWS (moto) uses dummy keys and is reachable only from the lab network.
  `~/.ssh`, `~/.ansible` and `~/.gitconfig` are never read. Everything is named `ans-*`; per-lab containers
  are labelled `ansiblelab.scenario`.
- Each lab keeps its runtime data in its own `.state/` directory, including SSH keys it generates.
  `.state/` is gitignored and never committed.

## Cleanup

| Lab | Remove everything |
|---|---|
| linux-lab | `./lab stop && docker rmi linuxlab/server:1` |
| swarm-lab | `./lab destroy && docker rmi swarmlab/node:1 swarmlab/webapp:1.0` |
| terra-labs | `./lab down && docker rmi terralab/moto:1`, then delete `cache/` to free ~1.6 GB |
| ansible-lab | `./lab down && docker rmi ansiblelab/ctl:2 ansiblelab/ctl:1 ansiblelab/node-debian12:1 ansiblelab/node-rocky9:1 ansiblelab/ee-base:1 ansiblelab/moto:1`, plus any `acme/ee:*` images you built; then delete `cache/` (~0.3 GB) |

## Repository layout

```text
.
├── linux-lab/            Linux server troubleshooting (26 scenarios)
├── swarm-lab/            Docker Swarm incidents (20 scenarios)
├── terra-labs/           Terraform/Terragrunt learn track (14) and incidents (37)
├── ansible-lab/          Ansible learn track (16) and incidents (47)
├── LICENSE               MIT
└── .gitignore            keeps generated state, caches and workspaces out of git
```

Every lab follows the same structure:

```text
<lab>/
├── lab                   the CLI (bash); ./lab help
├── lib/                  helpers shared by the CLI and scenario scripts
├── infra/                images and base config for the lab machines
├── scenarios/<ID>-<name>/
│   ├── ticket.md         symptoms and the Test line (definition of done)
│   ├── hints.md          progressive hints
│   ├── compose.yml       the machines for this scenario (linux-lab)
│   ├── files/            code and config "as found" (swarm-lab, terra-labs)
│   └── .lab/             setup.sh, verify.sh, solve.sh, solution.md (spoilers)
├── docs/                 how faults are built, plus catalogs and interview questions
├── PLAN.md               design decisions and research
├── README.md             full guide for the lab
├── .state/               runtime state, generated SSH keys (gitignored)
├── cache/                downloaded binaries and images (gitignored)
└── workspace/            your working copy for the current scenario (gitignored)
```

Lab-specific parts:

- **linux-lab**: `infra/hosts.yml` (machine definitions), `infra/server/` (Debian + systemd image).
- **swarm-lab**: `infra/compose.yml` (nodes, registry, legacy API), `infra/node/` (node image),
  `infra/legacy/` (legacy API outside the swarm), `images/webapp/` (the demo app the incidents run on).
- **terra-labs**:
  - `learn/L01-L14/`: the guided track, same anatomy as the scenarios
  - `scenarios/*/scenario.yaml`: scenario metadata
  - `infra/moto/`: the fake-AWS image, with a small fidelity patch
  - `infra/terraformrc.tpl`: offline provider mirror config
  - `tools/catalog.py`: regenerates `docs/CATALOG.md`
  - `versions.env`: pinned tool and provider versions
- **ansible-lab**:
  - `learn/L01-L16/`: the guided track; `scenarios/*/scenario.yaml`: metadata (nodes, level, wave)
  - `infra/ctl/`, `infra/ctl2/`: the controller image (ansible-core and tools; wave-2 layer with
    ansible-rulebook, boto3 and offline `ansible-test`)
  - `infra/node/`: Debian 12 and Rocky 9 node images; `infra/repo/`: the offline apt/dnf mirror
  - `infra/ee-base/`, `infra/moto/`, `infra/eda/`: execution-environment base, fake AWS, EDA activation
  - `tools/catalog.py`: regenerates `docs/CATALOG.md`; `versions.env`: pinned versions

## Documentation

| Document | What's inside |
|---|---|
| [linux-lab/README.md](linux-lab/README.md) | Network diagram, all 26 scenarios, rules, safety, maintenance |
| [linux-lab/docs/FAULTS.md](linux-lab/docs/FAULTS.md) | How each fault is emulated; build your own |
| [swarm-lab/README.md](swarm-lab/README.md) | How to play, all 20 incidents, chaos mode, cheat sheet |
| [swarm-lab/docs/FAULT-INJECTION.md](swarm-lab/docs/FAULT-INJECTION.md) | How network and infrastructure faults are injected |
| [terra-labs/README.md](terra-labs/README.md) | Learn track, all 37 incidents, rules, safety |
| [terra-labs/docs/FAULTS.md](terra-labs/docs/FAULTS.md) | House rules and helpers for writing scenarios |
| [terra-labs/docs/CATALOG.md](terra-labs/docs/CATALOG.md) | Every lab with its root cause (**spoilers**) |
| [terra-labs/docs/INTERVIEW-QUESTIONS.md](terra-labs/docs/INTERVIEW-QUESTIONS.md) | Terraform and Terragrunt interview questions, with the key points of a good answer |
| [ansible-lab/README.md](ansible-lab/README.md) | Learn track, all 47 incidents, interview mode, rules, safety |
| [ansible-lab/docs/FAULTS.md](ansible-lab/docs/FAULTS.md) | How the faults are built, the environment's fidelity, Ansible surprises found while building |
| [ansible-lab/docs/CATALOG.md](ansible-lab/docs/CATALOG.md) | Every lab with its root cause (**spoilers**) |
| [ansible-lab/docs/INTERVIEW-QUESTIONS.md](ansible-lab/docs/INTERVIEW-QUESTIONS.md) | Ansible interview questions, each linked to the lab that practises it |
| `*/PLAN.md` | Design decisions, research and build history of each lab |

## Contributing

Issues and pull requests are welcome, whether new scenarios, fixes or better tickets.

1. Read the lab's fault guide: [linux-lab](linux-lab/docs/FAULTS.md),
   [swarm-lab](swarm-lab/docs/FAULT-INJECTION.md), [terra-labs](terra-labs/docs/FAULTS.md) or
   [ansible-lab](ansible-lab/docs/FAULTS.md).
2. Add `scenarios/<ID>-<kebab-name>/` with the structure shown above. The ticket describes symptoms
   only, and its **Test** line says what "fixed" means.
3. `./lab selftest <id>` must report `broken:ok fixed:ok`: the check fails after setup and passes
   after the reference fix. Before a release, run `./lab selftest all` (about 15 min for linux-lab,
   25 for swarm-lab, 45 for terra-labs and ~75 for ansible-lab).
4. To bump tool versions in terra-labs or ansible-lab, edit `versions.env`, then run `./lab build` and
   `./lab selftest all`. After adding a terra-labs or ansible-lab scenario, regenerate the catalog with
   `python3 tools/catalog.py .`.

## License

[MIT](LICENSE)
