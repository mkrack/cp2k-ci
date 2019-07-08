#!/bin/bash -e

# author: Ole Schuett

CLUSTER_NAME="cp2k-cluster"

set -x

# node-taints are still a beta feature

for CPUS in 8 16 32 ; do
    #gcloud container node-pools delete pool-highcpu-${CPUS}-haswell
    gcloud beta container node-pools create pool-highcpu-${CPUS}-haswell \
       --cluster="${CLUSTER_NAME}" \
       --machine-type="n1-highcpu-${CPUS}" \
       --min-cpu-platform="Intel Haswell" \
       --preemptible \
       --enable-autoupgrade \
       --enable-autorepair \
       --enable-autoscaling \
       --max-nodes=4 \
       --min-nodes=0 \
       --num-nodes=0 \
       --node-taints="costly=true:NoSchedule"

    gcloud beta container node-pools create pool-highcpu-${CPUS}-skylake \
        --cluster="${CLUSTER_NAME}" \
        --machine-type="n1-highcpu-${CPUS}" \
        --min-cpu-platform="Intel Skylake" \
        --preemptible \
        --enable-autoupgrade \
        --enable-autorepair \
        --enable-autoscaling \
        --max-nodes=4 \
        --min-nodes=0 \
        --num-nodes=0 \
        --node-taints="costly=true:NoSchedule"
done

gcloud beta container node-pools create pool-highcpu-16-haswell-tesla-k80 \
       --cluster="${CLUSTER_NAME}" \
       --machine-type="n1-highcpu-16" \
       --accelerator="type=nvidia-tesla-k80,count=2" \
       --min-cpu-platform="Intel Haswell" \
       --preemptible \
       --enable-autoupgrade \
       --enable-autorepair \
       --enable-autoscaling \
       --max-nodes=1 \
       --min-nodes=0 \
       --num-nodes=0 \
       --node-taints="costly=true:NoSchedule"

gcloud beta container node-pools create pool-highcpu-8-haswell-tesla-k80 \
       --cluster="${CLUSTER_NAME}" \
       --machine-type="n1-highcpu-8" \
       --accelerator="type=nvidia-tesla-k80,count=1" \
       --min-cpu-platform="Intel Haswell" \
       --preemptible \
       --enable-autoupgrade \
       --enable-autorepair \
       --enable-autoscaling \
       --max-nodes=1 \
       --min-nodes=0 \
       --num-nodes=0 \
       --node-taints="costly=true:NoSchedule"

# There is no n1-highcpu-24 machine type.
# Using custom type with same 0.9GB/vCPU ratio routed up to multiple of 256MiB.
gcloud container node-pools create pool-tesla-p4-haswell-24 \
       --cluster="${CLUSTER_NAME}" \
       --machine-type="custom-24-22272" \
       --accelerator="type=nvidia-tesla-p4,count=1" \
       --min-cpu-platform="Intel Haswell" \
       --preemptible \
       --enable-autoupgrade \
       --enable-autorepair \
       --enable-autoscaling \
       --max-nodes=1 \
       --min-nodes=0 \
       --num-nodes=0 \
       --node-taints="costly=true:NoSchedule"

#EOF
