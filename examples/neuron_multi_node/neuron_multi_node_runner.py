import asyncio
import os

from vllm.entrypoints.neuron_multi_node import api_server


def main():
    rank_id = int(os.getenv("NEURON_RANK_ID", "0"))
    if rank_id == 0:
        asyncio.run(master())
    else:
        asyncio.run(main_worker())


async def master():
    args, engine = await api_server.initialize_worker()
    await api_server.run_master(args, engine)
    # call asyn llm engine


async def main_worker():
    args, engine = await api_server.initialize_worker()
    worker = engine.engine.model_executor.driver_worker
    while True:
        worker.execute_model()


if __name__ == "__main__":
    main()
