# Notes: OIDC and SSM

## OIDC (OpenID Connect)
OIDC lets one service prove its identity to another with a signed token.
In this project GitHub is the identity provider and AWS is the service that trusts it.

How it works here:
1. A GitHub Actions job starts and GitHub issues a signed token.
2. The token names the repo and environment (the `sub` claim).
3. The job sends the token to AWS STS.
4. STS checks the signature, expiry and the role's trust policy.
5. If they match, STS returns temporary credentials (about an hour).

Why not access keys? Keys are long-lived secrets that can leak.
OIDC credentials expire quickly and only work for the matching repo and environment.

## SSH vs SSM
- SSH: connects to port 22 with a key pair. Needs an open port and key management.
- SSM: AWS delivers the command to an agent on the server. No open inbound port,
  no keys, access controlled by IAM, and actions are logged.

In cloudops-toolkit the deploy job uses SSM Run Command to run `git pull` on the EC2 server.
An instance must be running and Online in SSM, otherwise the deploy fails with `InvalidInstanceId`.

## Least privilege
Each role has only the permissions it needs: the plan role is read-only,
and the apply role can only be assumed from the `production` environment.
