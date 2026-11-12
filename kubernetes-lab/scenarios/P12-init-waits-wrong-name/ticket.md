# orders-api stuck in Init:0/1
**INC-2412** · P2 · Reporter: orders team

After the DB team moved our database Service to the "new naming standard", `orders-api` (namespace
`orders-db`, `workspace/P12/orders-api.yaml`) stays in **Init:0/1**. The database itself runs fine.
The init container makes sure the database exists before the API starts - keep that.

**Test**: orders-api is Running and Ready, and it still waits for the database in an init container.
