FROM alpine:3.7

RUN \
# apk add installs the following
 apk add \
   busybox-extras \
   git \
   curl \
   python \
   py-pip \
   py-boto \
   py-dateutil \
   py-httplib2 \
   py-jinja2 \
   py-paramiko \
   py-setuptools \
   py-yaml \
   openssh-client \
   bash \
   tar && \
 pip install --upgrade pip

# Makes the Ansible directories
RUN mkdir /etc/ansible /ansible

# Downloads the Ansible tar (curl) and saves it (-o)
RUN \
  curl -fsSL https://releases.ansible.com/ansible/ansible-2.2.2.0.tar.gz -o ansible.tar.gz
# Extracts Ansible from the tar file
RUN \
  tar -xzf ansible.tar.gz -C ansible --strip-components 1 && \
  rm -fr ansible.tar.gz /ansible/docs /ansible/examples /ansible/packaging

# Makes a directory for ansible playbooks
RUN mkdir -p /ansible/playbooks
RUN mkdir -p /ansible/inventories

# Makes the playbooks directory the working directory
WORKDIR /ansible/playbooks

# Sets environment variables
ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING False
ENV ANSIBLE_RETRY_FILES_ENABLED False
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PATH /ansible/bin:$PATH
ENV PYTHONPATH /ansible/lib
ENV ANSIBLE_INVENTORY /ansible/playbooks/test-cases/inventory
ENV TEST_CASE_RUNNER main.yml

# Copy your ansible configuration into the image
COPY test-cases /ansible/playbooks/test-cases
COPY entrypoint.sh /ansible/playbooks/test-cases/entrypoint.sh

# Run ansible to configure things
# Sets entry point (same as running ansible-playbook)
CMD ["sh", "/ansible/playbooks/test-cases/entrypoint.sh"]