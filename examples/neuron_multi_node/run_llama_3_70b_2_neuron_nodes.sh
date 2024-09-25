#!/bin/bash

set -x #echo on

# Use environment variables with defaults

if [ -z "$K8S_MASTER_ADDR" ]; then
	MASTER_ADDR=(`scontrol show hostnames $SLURM_JOB_NODELIST`)
else
	MASTER_ADDR=$K8S_MASTER_ADDR
fi
NEURON_RT_ROOT_COMM_ID=$MASTER_ADDR:8990
NEURON_RANK_ID=${K8S_NEURON_RANK_ID:-$SLURM_NODEID}
NEURON_LOCAL_TP=${K8S_NEURON_LOCAL_TP:-32}
VLLM_HOST_IP=$MASTER_ADDR
VLLM_PORT=8989

export NEURON_RT_ROOT_COMM_ID
export NEURON_RANK_ID
export NEURON_LOCAL_TP
export VLLM_HOST_IP
export VLLM_PORT

echo $NEURON_RT_ROOT_COMM_ID
echo $NEURON_RANK_ID
echo $NEURON_LOCAL_TP
echo $VLLM_HOST_IP
echo $VLLM_PORT

# Install RT (commented out for safety)
echo "running script"
if [ -n "$SLURM_NODEID" ]; then
	sudo dpkg -i ./neuron_dependencies/*.deb
fi

echo "runtime setup done"
echo "$(apt list --installed | grep neuron)"

sudo modprobe -r neuron; sudo modprobe neuron
export FI_EFA_USE_DEVICE_RDMA=1
export FI_PROVIDER=efa

pip list | grep neuron
sudo apt list --installed | grep neuron

# Export environment variables
export NEURONX_DUMP_TO="./Meta_Llama31_70b_compiler_work_dir/"

python neuron_multi_node_runner.py --model="meta-llama-3-1/Meta-Llama-3-1-70B" --max-num-seqs=2 --max-model-len=128 --tensor-parallel-size=64 --port=8080 --device="neuron"
