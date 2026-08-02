# hedronite-devops-lab

## What this is

An ephemeral DevOps lab in a single container image: Terraform with multi-version tfenv, kubectl, helm, krew, k9s, Go, Python via uv, Rust, Rails 7, R with tidyverse, Prometheus, Grafana, and the bench tools (gh, jq, yq, tmux, vim, neovim, zsh). Start it, work, throw it away. Anything worth keeping lives in a bind-mount; the container itself holds nothing precious. It exists so certification practice and infrastructure experiments run in a room that resets to clean every time you enter.

## Install

Pick a container runtime:

- **OrbStack** (recommended): fastest VirtioFS bind-mounts on macOS and native Rosetta for running amd64 images on Apple silicon. `brew install orbstack`.
- **Colima**: open-source, same Rosetta path when started with:

```bash
colima start --arch aarch64 --vm-type=vz --vz-rosetta
```

- **Docker Desktop**: works fine if you already run it.

Pull the image:

```bash
docker pull ghcr.io/hedronite/lab:latest
```

Install the shell function. Clone this repo and source the file:

```zsh
source /path/to/hedronite-devops-lab/shell/lab.zsh
```

or source it straight from the tag:

```zsh
source <(curl -fsSL https://raw.githubusercontent.com/Hedronite/hedronite-devops-lab/v0.1.0/shell/lab.zsh)
```

Put whichever line you choose in `~/.zshrc`.

## Usage

Four patterns cover everything.

An interactive shell:

```bash
lab
```

One command, then gone:

```bash
lab terraform version
```

Chained, each command in its own fresh container:

```bash
lab terraform init && lab terraform plan
```

Toolchain runners pass through unchanged:

```bash
lab uv run pytest
```

Every invocation starts a new container and removes it on exit. State that must survive belongs under `/workspace`.

## What's mounted

| Container path | Host path | Mode | Purpose |
|---|---|---|---|
| `/workspace` | `~/lab-workspaces/default` (override: `LAB_WORKSPACE`) | rw | scratch that survives the container |
| `/labs` | `~/Obsidian/Atrium/Atrium/Archmagus-Stack/Sovereign-Bootcamp` | ro | practice corpus |
| `/tomes` | `~/Obsidian/Atrium/Atrium/09-Tomes` | ro | reference books |
| `/root/.aws` | `~/.aws` | ro | AWS credentials |
| `/root/.config/gcloud` | `~/.config/gcloud` | ro | GCP credentials |
| `/root/.azure` | `~/.azure` | ro | Azure credentials |
| `/root/.kube` | `~/.kube` | ro | cluster access |
| `/root/.ssh` | `~/.ssh` | ro | git identity |

Read-only is deliberate for everything except `/workspace`. The container can use your credentials and your corpus; it cannot alter either. No experiment, however badly it goes, reaches back into the source material.

## Cloud credentials

The image contains no credentials and never will. No Dockerfile layer copies a secret, and the `.gitignore` blocks the common leak paths. Credentials reach the container only through the read-only mounts above.

Each cloud CLI runs under a `[lab]` profile, so lab work uses scoped, revocable access instead of your daily identity:

```bash
bash scripts/setup-lab-profile.sh
```

The script prompts per cloud, skips anything already configured, and is safe to re-run. Inside the container, select the profile explicitly: `AWS_PROFILE=lab`, `gcloud config configurations activate lab`, or the Azure service principal the script created.

## Kubernetes

kubectl in the container points wherever your host kubeconfig points. The intended target is a k3s node named `hedronite-devops-lab`, joined as a worker to an existing control plane. Once the node exists and its context is merged into `~/.kube/config`, select it on the host:

```bash
kubectl config use-context hedronite-devops-lab
```

The kubeconfig mount is read-only, so context switching stays a host-side act. Verify reach from inside:

```bash
lab kubectl get nodes
```

`labs-examples/k8s/` holds a first deployment to run against the node.

## Observability

Two modes, one stack. For scratch work the image ships `prometheus` and `grafana` as plain binaries; start them inside the container, point them at anything reachable, discard them with the container. For monitoring that persists, `helm/prom-stack-values.yaml` configures kube-prometheus-stack on the lab node with 15-day retention and `local-path` storage. `labs-examples/obs/` walks through both.

## Philosophy

Cattle, not pets. A lab machine you configure by hand becomes a machine you fear to lose, and fear is the wrong relationship with practice infrastructure. So the container is disposable by construction: every run starts from the same image, and the image rebuilds from one Dockerfile anyone can read.

The partition does the real work. Study material mounts read-only. Scratch lands in `/workspace`. The container holds nothing. Delete it mid-session and you lose only a process table. If losing a container ever costs you something, a file sat in the wrong place — the fix is to move the file, never to protect the container.

## Contributing / Extending

Tool versions are `ARG`s at the top of the Dockerfile. Bump one, tag a release, and CI publishes multi-arch images to GHCR:

```bash
git tag v0.1.1
git push origin v0.1.1
```

To add a language, add one layer in the toolchain section of the Dockerfile and end it with a smoke command that proves the install, matching the existing layers. Keep fast-changing layers low in the file so rebuilds stay cheap.

Fork freely. MIT terms apply.

## License

MIT. See [LICENSE](LICENSE).
