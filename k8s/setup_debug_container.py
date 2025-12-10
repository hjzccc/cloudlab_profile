from uuid import uuid4
from kubernetes import client, config

KUBECONFIG_PATH = "<kubectl_config_path>"
SERVICEWEAVER_POD_LABEL = "<service_name>"  # eg. "serviceweaver/app=server.out"

config.load_kube_config(KUBECONFIG_PATH)
api_instance = client.CoreV1Api()

debug_container_name = f"ssh-debugger{uuid4()}"


def setup_debug_container(pod_name: str, namespace: str = "default") -> None:
    debug_container = client.V1EphemeralContainer(
        name=debug_container_name,
        image="h21565897/distributeddebugger:144",
        target_container_name="serviceweaver",
        image_pull_policy="Always",
        stdin=True,
        tty=True,
        security_context=client.V1SecurityContext(privileged=True),
    )
    patch_body = {"spec": {"ephemeralContainers": [debug_container]}}

    api_instance.patch_namespaced_pod_ephemeralcontainers(
        name=pod_name,
        namespace=namespace,
        body=patch_body,
    )


if __name__ == "__main__":
    pods = api_instance.list_namespaced_pod(
        namespace="default", label_selector=SERVICEWEAVER_POD_LABEL
    )
    print(f"Found {len(pods.items)} pods")

    for pod in pods.items:
        setup_debug_container(pod.metadata.name)
        print(f"Debug container injected for pod {pod.metadata.name}")