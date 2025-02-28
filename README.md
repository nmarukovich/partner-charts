# partner-charts

This repository is reserved for partner charts in the Rancher's v2.5+ catalog. As part of this catalog,
all charts will benefit of a cloud native packaging system that directly references an upstream chart
from a Helm or git repository and automates applying Rancher specific modifications and adding overlay
files on top of it.

## Requirements

* Chart must be Helm 3 compatible.

    Helm 2 installed CRDs via an `helm.sh/hook: crd-install` annotation that installed
    CRDs via a special hook. In Helm 3, this annotation was removed in favor of a `crds/`
    directory where your CRDs should now reside. Templating and upgrading CRDs is also no
    longer supported by default. Users who need to support templating / upgrading CRDs should
    use a separate CRD chart that installs the CRDs via the `templates/` directory instead.
    Leaving this hook in your chart will not cause it to break, but will cause the Helm logs
    to emit the warning `manifest_sorter.go:175: info: skipping unknown hook: "crd-install"`
    on an install or upgrade.

    In addition, starting [Helm 3.5.2](https://github.com/helm/helm/releases/tag/v3.5.2), Helm is stricter about parsing semver strings. Therefore, to ensure that your chart is deployable via Helm 3.5.2, your chart must have a semver-compliant version.

    More information:
    * Supported Hooks: https://helm.sh/docs/topics/charts_hooks/
    * Helm 2 to 3 migration: https://helm.sh/docs/topics/v2_v3_migration/
    * Managing CRDs and best practices: https://helm.sh/docs/chart_best_practices/custom_resource_definitions/
    * Semver Rules: https://semver.org/

* Chart must be in a hosted [Helm](https://helm.sh/docs/topics/chart_repository/) or Git repository that we can reference.

* Chart must have the following Rancher specific add-ons (More details on this below).
    * kubeVersion set in the chart's metadata
    * app-readme.md
    * questions.yaml (Optional)

## Workflow

#### 1. Fork the [Rancher Partner Charts](https://github.com/rancher/partner-charts/) repository
#### 2. Clone your fork and ensure the main-source branch is checked out
```bash
git clone -b main-source git@github.com:<your_github>/partner-charts.git
```
#### 3. Create subdirectories in **packages** in the form of `<vendor>/<chart>`
```bash
cd partner-charts
mkdir -p packages/suse/kubewarden-controller

```
#### 4. Create your [upstream.yaml](#configuration-file)
Some [examples](#examples) are provided below
```bash
cat <<EOF > packages/suse/kubewarden-controller/upstream.yaml
HelmRepo: https://charts.kubewarden.io
HelmChart: kubewarden-controller
Vendor: SUSE
DisplayName: Kubewarden Controller
ChartMetadata:
  kubeVersion: '>=1.21-0'
  icon: https://www.kubewarden.io/images/icon-kubewarden.svg
EOF
```
#### 5. [Create 'overlay' files](#overlay)
Create any add-on files such as an app-readme.md and questions.yaml in an 'overlay' subdirectory (Optional)
```bash
mkdir packages/suse/kubewarden-controller/overlay
echo "Example app-readme.md" > packages/suse/kubewarden-controller/overlay/app-readme.md
```
#### 6. Commit your packages directory
```bash
git add packages/suse/kubewarden-controller
git commit -m "Submitting suse/kubewarden-controller"
```
#### 7. [Test your configuration](#testing-your-configuration)
#### 8. Push your commit and open a pull request
```bash
git push origin main-source

# Open Your Pull Request
```

## Testing your configuration
If you would like to test your configuration using the CI tool, simply run the provided script in `scripts/pull-ci-scripts` to download the binary. The 'auto' function is what will be run to download and store your chart.

#### 1. Download the binary
```bash
scripts/pull-ci-scripts
```
#### 2. Set the **PACKAGE** environment variable to your chart
You can confirm the package entry with `bin/partner-charts-ci list` which will list all detected charts with a configuration file.
```bash
export PACKAGE=<vendor>/<chart>
```
#### 3. Run the 'auto' or 'stage' function
The 'auto' subcommand will run the complete CI process.
The 'stage' subcommand will do the same process but will not create a git commit when it completes.
```bash
bin/partner-charts-ci auto
```
#### 4. Validate your changes
```bash
bin/partner-charts-ci validate
```

## Overlay

Any files placed in the `packages/<vendor>/<chart>/overlay` directory will be overlayed onto the chart. This allows for adding or overwriting files within the chart as needed. The primary intended purpose is for adding the optional app-readme.md and questions.yaml files but it may be used for adding or replacing any chart files.

- `app-readme.md` - Write a brief description of the app and how to use it. It's recommended to keep
it short as the longer `README.md` in your chart will be displayed in the UI as detailed description.

- `questions.yaml` - Defines a set of questions to display in the chart's installation page in order for users to
answer them and configure the chart using the UI instead of modifying the chart's values file directly.

#### Questions example
[Variable Reference](https://docs.ranchermanager.rancher.io/how-to-guides/new-user-guides/helm-charts-in-rancher/create-apps#question-variable-reference)
```yaml
questions:
- variable: password
  default: ""
  required: true
  type: password
  label: Admin Password
  group: "Global Settings"
- variable: service.type
  default: "ClusterIP"
  type: enum
  group: "Service Settings"
  options:
    - "ClusterIP"
    - "NodePort"
    - "LoadBalancer"
  required: true
  label: Service Type
  show_subquestion_if: "NodePort"
  subquestions:
  - variable: service.nodePort
    default: ""
    description: "NodePort port number (to set explicitly, choose port between 30000-32767)"
    type: int
    min: 30000
    max: 32767
    label: Service NodePort
```

## Configuration File

The tool reads a configuration yaml, `upstream.yaml`, to know where to fetch the upstream chart. This file is also able to define any alterations for valid variables in the Chart.yaml as described by [Helm](https://helm.sh/docs/topics/charts/#the-chartyaml-file).


Options for `upstream.yaml`
| Variable | Requires | Description |
| ------------- | ------------- |------------- |
| ArtifactHubPackage | ArtifactHubRepo | Defines the package to pull from the defined ArtifactHubRepo
| ArtifactHubRepo | ArtifactHubPackage | Defines the repo to access on Artifact Hub
| AutoInstall | | Allows setting a required additional chart to deploy prior to current chart, such as a dedicated CRDs chart
| ChartMetadata | | Allows setting/overriding the value of any valid [Chart.yaml variable](https://helm.sh/docs/topics/charts/#the-chartyaml-file)
| DisplayName | | Sets the name the chart will be listed under in the Rancher UI
| Experimental | | Adds the 'experimental' annotation which adds a flag on the UI entry
| Fetch | HelmChart, HelmRepo | Selects set of charts to pull from upstream.<br />- **latest** will pull only the latest chart version *default*<br />- **newer** will pull all newer versions than currently stored<br />- **all** will pull all versions
| GitBranch | GitRepo | Defines which branch to pull from the upstream GitRepo
| GitHubRelease | GitRepo | If true, will pull latest GitHub release from repo. Requires GitHub URL
| GitRepo | | Defines the git repo to pull from
| GitSubdirectory | GitRepo | Allows selection of a subdirectory of the upstream git repo to pull the chart from
| HelmChart | HelmRepo | Defines which chart to pull from the upstream Helm repo
| HelmRepo | HelmChart | Defines the upstream Helm repo to pull from
| Hidden | | Adds the 'hidden' annotation which hides the chart from the Rancher UI
| Namespace | | Addes the 'namespace' annotation which hard-codes a deployment namespace for the chart
| PackageVersion | | Used to generate new patch version of chart
| ReleaseName | | Sets the value of the release-name Rancher annotation. Defaults to the chart name
| TrackVersions | HelmChart, HelmRepo | Allows selection of multiple *Major.Minor* versions to track from upstream independently.
| Vendor | | Sets the vendor name providing the chart

## Examples
### Helm Repo
#### Minimal Requirements
```yaml
HelmRepo: https://charts.kubewarden.io
HelmChart: kubewarden-controller
Vendor: SUSE
DisplayName: Kubewarden Controller
```
#### Multiple Release Streams
```yaml
HelmRepo: https://charts.kubewarden.io
HelmChart: kubewarden-controller
Vendor: SUSE
DisplayName: Kubewarden Controller
Fetch: newer
TrackVersions:
  - 0.4
  - 1.0
  - 1.1
ChartMetadata:
  kubeVersion: '>=1.21-0'
  icon: https://www.kubewarden.io/images/icon-kubewarden.svg
```

### Artifact Hub
```yaml
ArtifactHubRepo: kubewarden
ArtifactHubPackage: kubewarden-controller
Vendor: SUSE
DisplayName: Kubewarden Controller
ChartMetadata:
  kubeVersion: '>=1.21-0'
  icon: https://www.kubewarden.io/images/icon-kubewarden.svg
```

### Git Repo
```yaml
GitRepo: https://github.com/kubewarden/helm-charts.git
GitBranch: main
GitSubdirectory: charts/kubewarden-controller
Vendor: SUSE
DisplayName: Kubewarden Controller
ChartMetadata:
  kubeVersion: '>=1.21-0'
  icon: https://www.kubewarden.io/images/icon-kubewarden.svg
```

### GitHub Release
```yaml
GitRepo: https://github.com/kubewarden/helm-charts.git
GitHubRelease: true
GitSubdirectory: charts/kubewarden-controller
Vendor: SUSE
DisplayName: Kubewarden Controller
ChartMetadata:
  kubeVersion: '>=1.21-0'
  icon: https://www.kubewarden.io/images/icon-kubewarden.svg
```
