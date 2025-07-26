## 🔧 **Terraform Architecture Overview**

### ✅ **Multi-Environment Setup**

* The configuration supports **`dev`**, **`stg`**, and **`prd`** environments using `terraform.workspace`.
* Region and AZs are dynamically mapped using locals (`region_map`, `az_1_map`, `az_2_map`) to deploy based on the active workspace.

---

## 🔩 **Main Components & Modules**

### 1. **VPC Module (`./modules/vpc`)**

Creates the network backbone.

* **VPC**: `172.168.0.0/16`
* **Subnets**:

  * `subnet-1`: `172.168.0.0/24` in AZ1
  * `subnet-2`: `172.168.1.0/24` in AZ2
* **Internet Gateway (IGW)**: To allow internet access.
* **Route Table**:

  * Route to `0.0.0.0/0` via IGW
  * Associated to both subnets
* **Network Interfaces (NICs)** for:

  * `app-1` in subnet-1
  * `app-2` in subnet-2
* **Elastic IPs (EIPs)** bound to each NIC

> 🔁 Outputs: `vpc_id`, subnet IDs, IGW ID, RT ID, NIC IDs

---

### 2. **Security Group Module (`./modules/security_group`)**

Provides unrestricted access (for demo/test):

```hcl
ingress + egress:
  from_port = 0
  to_port = 0
  protocol = -1 (all)
  cidr_blocks = ["0.0.0.0/0"]
```

> 🛡️ **⚠️ Note**: This opens **all traffic to/from anywhere**, which is **insecure for production**.

---

### 3. **AMI Data Source**

Fetches latest Amazon Linux 2 AMI from official `amazon` owner.

---

### 4. **TLS & EC2 Key Pair**

* RSA key pair (4096-bit) is created using `tls_private_key` provider.
* Key is uploaded to AWS with `aws_key_pair`.

---

### 5. **EC2 Instances Modules (`./modules/app-1` and `./modules/app-2`)**

Two EC2 instances launched:

* Type: `t2.micro`
* NICs: Bound to previously created NICs
* **User data**: Installs and configures NGINX, serves a simple HTML page:

  * `/app-1`: “This is app-1”
  * `/app-2`: “This is app-2”

---

### 6. **Application Load Balancer Module (`./modules/alb`)**

* **Type**: Application Load Balancer (`internal = true`)
* **Subnet span**: Across subnet-1 and subnet-2
* **Security group**: Shared with EC2
* **Target groups**:

  * `app-1_tg`: forwards to `app-1`
  * `app-2_tg`: forwards to `app-2`
* **Listeners**:

  * Port 80 (HTTP)
  * Path-based routing:

    * `/app-1` → app-1
    * `/app-2` → app-2
    * Default 404 for unmatched paths

---

## 📤 Outputs

Your `output.tf` provides:

* IDs for VPC, subnets, route table, IGW, SG
* EC2 IDs and their NICs
* Load Balancer ID, ARN, listener ARN
* Target group ARNs

This makes the infrastructure reusable and integrable with other modules or outputs.

---

## 🗂️ Folder Structure

```
.
├── main.tf
├── output.tf
├── variables.tf
├── modules/
│   ├── vpc/
│   ├── alb/
│   ├── security_group/
│   ├── app-1/
│   └── app-2/
```

Each module has its own `main.tf`, `variable.tf`, `output.tf`, making the code **clean**, **scalable**, and **reusable**.

---
## 🧱 Infrastructure Architecture Diagram (Textual)

```
                             ┌────────────────────────────┐
                             │   Application Load Balancer│
                             │      (Internal, Path-Based)│
                             └──────────┬───────┬─────────┘
                                        │       │
                                  /app-1│       │/app-2
                                        ▼       ▼
                               ┌────────────┐ ┌────────────┐
                               │  EC2 App-1 │ │  EC2 App-2 │
                               └────────────┘ └────────────┘
                                  │               │
                                  ▼               ▼
                             Subnet-1         Subnet-2
                              (AZ1)             (AZ2)
                                  \               /
                                   \             /
                                    ▼           ▼
                                Route Table + Internet Gateway
                                          ▼
                                      VPC (172.168.0.0/16)
```
## 📦 Summary

| Resource            | Details                                                      |
| ------------------- | ------------------------------------------------------------ |
| **VPC**             | Custom CIDR, 2 subnets, IGW, route table                     |
| **EC2 Instances**   | Amazon Linux 2, nginx, one per subnet                        |
| **Security Group**  | All ports/protocols open (demo only)                         |
| **Key Pair**        | Dynamically created RSA key                                  |
| **ALB**             | Internal, Application LB, path-based routing                 |
| **Workspace-Aware** | Automatically chooses region and AZs per `dev`, `stg`, `prd` |
| **Modular**         | Each resource class is a reusable module                     |
| **Outputs**         | Rich, usable outputs for chaining or debugging               |

---
