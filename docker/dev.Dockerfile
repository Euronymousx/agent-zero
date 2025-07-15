FROM python:3.12-slim

# ─────────────────────────────────────────────────────────────────────────────
# OS packages
# ─────────────────────────────────────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        bash \
        bash-completion \
        build-essential \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────────────────────────
# Poetry (system-wide, no virtual-envs)
# ─────────────────────────────────────────────────────────────────────────────
ENV POETRY_HOME=/opt/poetry
ENV PATH="$POETRY_HOME/bin:$PATH"
ENV POETRY_VIRTUALENVS_CREATE=false
ENV POETRY_VIRTUALENVS_IN_PROJECT=false

RUN curl -sSL https://install.python-poetry.org | python - --yes

# ─────────────────────────────────────────────────────────────────────────────
# Non-root user
# ─────────────────────────────────────────────────────────────────────────────
RUN useradd -m -u 1000 agent && \
    echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/agent

# ─────────────────────────────────────────────────────────────────────────────
# Project sources & dependencies
# ─────────────────────────────────────────────────────────────────────────────
WORKDIR /workspace
COPY . /workspace

# install deps into global site-packages (still root)
RUN poetry install --with dev --no-root --no-interaction

# trust repo for all users to avoid UID-mismatch errors
RUN git config --system --add safe.directory /workspace

# fix permissions so unprivileged user can write
RUN chown -R agent:agent /workspace

USER agent

EXPOSE 8000
CMD ["poetry", "run", "uvicorn", "agent_zero.cli.app:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]
