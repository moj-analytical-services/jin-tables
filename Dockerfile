FROM ghcr.io/ministryofjustice/analytical-platform-airflow-r-base:1.11.0@sha256:dc462ef8c58bdb220f77bec1a41982ba62086bed28b34a2debeea9318c85d746

ARG MOJAP_IMAGE_VERSION="default"
ENV MOJAP_IMAGE_VERSION=${MOJAP_IMAGE_VERSION}


# Create a working directory
WORKDIR /pocketbook

# Add R package requirements and scripts
COPY renv.lock renv.lock
COPY scripts/ scripts/

# Give working directory permissions to everyone
RUN chmod -R 777 .

# Use the latest repos for R
RUN R -e "options(repos = 'cran.rstudio.com')"
# Install renv globally
RUN R -e "install.packages('renv')"

# Create a user with a home directory, which is necessary for renv
# The user id must be the same as defined in the Airflow DAG
RUN adduser --uid 1337 daguser
USER daguser

# Inititalise renv...
RUN R -e "renv::init()"

# ... and restore the R environment
RUN R -e 'renv::restore()'

# Run the DAG task
ENTRYPOINT Rscript scripts/run.R

# Below is an example of how to use the base image
# COPY renv.lock renv.lock
# RUN <<EOF
# R -e "install.packages('renv')"
# R -e "renv::init()"
# R -e "renv::restore()"
# EOF

# COPY --chown=nobody:nobody --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh
# ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
