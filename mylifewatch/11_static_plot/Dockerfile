FROM docker.io/library/base-my

RUN which python3

# Copy dependencies and install them
COPY req req
RUN Rscript req/exe.R

# Create new working directory
WORKDIR wrp

# copy the folder code and the main.r code
ADD code code
ADD main.r .


