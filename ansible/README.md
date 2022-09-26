# PPA Upload Automation

## Create Python venv

Create a new Virtual Environment
```
python3 -m venv ansible-venv
```

Install Ansible and module requirements into the venv
```
source ansible-venv/bin/activate
pip install ansible
pip install docker
pip install jmespath
pip install launchpadlib
```

## Running the playbook

Create a secrets file somewhere and secure it, encyrpt with ansible-vault or external
solution such as Hashi Vault. The secrets file will contain your sensitive variables.

```yaml
---
secret_access_token: <oauth token>
secret_access_secret: <oauth secret>
secret_maintainer_email: "Tux <secret-no-spam@email>"
secret_signing_key: <launchpad signing key id>
secret_gpg_path: /home/user/.ansible-gnupg
```

Then modify the playbook and set the correct values for `lp_project` and `lp_ppa`, as well
as the paths to the mainline kernel source, and the output folder for packages.

```yaml
  vars:
    lp_project:                   "~tuxinvader"
    lp_ppa:                       "lts-mainline"
    lp_lts_version:               "focal"
    lp_singing_key:               "{{ secret_signing_key }}"
    lp_maintainer:                "{{ secret_maintainer_email }}"

    build_flavour:                "generic"
    build_gpg_path:               "{{ secret_gpg_path }}"
    build_kernel_source_path:     "/usr/local/src/cod/mainline"
    build_packages_path:          "/usr/local/src/cod/debs"

    kernel_series:                "stable"
    kernel_major_minor:           ""
```

You can also set the `kernel_series` to one of `stable`, `mainline`, or `longterm`.
The `mainline` option will build the latest RC kernel, but if you chose the
`longterm` option you should also set `kernel_major_minor` to match one of the
LTS kernels (eg 5.15), otherwise you'll get the oldest one (eg 4.9.x).

Once you've made those changes, you can run the playbook on cron to keep the PPA
updated with the latest kernels

```
source ansible-venv/bin/activate
ansible-playbook -e @~/.launchpadlib_ansible_secrets.yml ppa-updater-playbook.yaml
```

