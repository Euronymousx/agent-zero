FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git curl build-essential bash-completion sudo \
    && rm -rf /var/lib/apt/lists/*

ENV POETRY_HOME=/opt/poetry
ENV PATH="$POETRY_HOME/bin:$PATH"
RUN curl -sSL https://install.python-poetry.org | POETRY_VERSION=1.8.2 python - --yes

RUN useradd -m -u 1000 agent \
    && echo "agent ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/agent

WORKDIR /workspace
COPY . /workspace
RUN chown -R agent:agent /workspace

USER agent
RUN poetry install --with dev --no-root

EXPOSE 8000
CMD ["poetry", "run", "uvicorn", "agent_zero.cli.app:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]
