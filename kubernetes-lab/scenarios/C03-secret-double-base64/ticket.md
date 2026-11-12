# cart can't log in to its Redis
**INC-2436** · P2 · Reporter: team cart

`cart` logs *authentication failed (invalid password?): WRONGPASS* since we moved its Redis password into our
own Secret (`workspace/C03/cart-secret.yaml`). We base64-encoded it as the docs say, and
`kubectl -n cart get secret cart-redis -o yaml` shows exactly that string. The password itself (Secret
`redis-auth`, used by Redis) is right and must not change.

**Test**: `cart` is Ready and its Redis connection works (`/ready` reports redis ok); Secret `cart-redis`
decodes to the same password as `redis-auth`; Redis still requires that password.
