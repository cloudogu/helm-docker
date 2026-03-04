helm-plugins-docker
===

Containerized Kubernetes Helm client with support for plugins 

# Bundled plugins

```bash
helm kubeval
helm values 
```

You can install additional plugins at runtime.
Even from git.
Even as unprivileged user.

# Usage

The image can be pulled with `$ docker pull ghcr.io/cloudogu/helm:latest`

If you desire a specific release, head over to [Releases](https://github.com/cloudogu/helm-docker/releases).