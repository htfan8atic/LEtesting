# Dedicated cloud VM build — LibreELEC PR #106

The repository's GitHub-hosted Actions runs #1–#4 did not reach compilation because Ubuntu package-server DNS failed. This alternative uses a **separate Ubuntu x86_64 cloud virtual machine** with its own storage and networking.

## Provision the VM

Choose any provider that allows SSH and an Ubuntu 24.04 LTS **x86_64 / AMD64** image (not ARM64). Suggested capacity: **16 vCPU, 32 GB RAM, 250 GB SSD**, with 8 vCPU / 16 GB as a slower alternative. These are sizing recommendations, not verified minimums. Permit outbound HTTPS and DNS. Cloud VMs generally cost money while running; check the provider's rate and shut the VM down or delete it after downloading the artifacts.

Log in with SSH as the default non-root Ubuntu user, then run:

```bash
sudo apt-get update
sudo apt-get install -y curl ca-certificates
curl -fL https://raw.githubusercontent.com/htfan8atic/LEtesting/main/cloud-vm/build-pr106.sh -o build-pr106.sh
less build-pr106.sh
bash build-pr106.sh
```

Review the script before execution. It uses `sudo apt-get` to install build dependencies, clones the upstream repo, pins **PR #106** to `f48accba93b374e369b46dae18ac6530b3062688`, checks and stages CB1, then runs `CB1_HDR10_AI=yes PROJECT=Generic ARCH=x86_64 OFFICIAL=no make image` as in the upstream instructions.

**Outputs if compilation succeeds:**

```text
~/le-pr106/output/LibreELEC-*.tar
~/le-pr106/output/SHA256SUMS
~/le-pr106/output/BUILD_SOURCE.txt
~/le-pr106/build.log
```

If build dependencies, downloads, patches, or memory limits fail, the script will stop. No result is guaranteed.

## Retrieve the result to your Windows PC

In Windows PowerShell (replace the host/IP and username):

```powershell
scp ubuntu@YOUR_VM_PUBLIC_IP:~/le-pr106/output/*.tar .
scp ubuntu@YOUR_VM_PUBLIC_IP:~/le-pr106/output/SHA256SUMS .
```

Verify the SHA256 digest, compare the version/architecture, back up LibreELEC, and preserve a rollback installation before applying an experimental update. This patch has not been hardware-validated on AMD 5800H; the VM only performs compilation and archive checks.

When finished, **delete the VM and associated disks** if you do not need them. Shutting down alone does not necessarily stop storage charges.
