FROM klakegg/hugo:ubuntu

RUN apt-get update && apt-get install -y git && apt-get clean all
    # "set -e\n"\
RUN echo \
    "#!/bin/bash\n"\
    "git config --global --add safe.directory /src\n"\
    "echo cmd: \"\$@\"\n"\
    "hugo \"\$@\"\n"\
    > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
