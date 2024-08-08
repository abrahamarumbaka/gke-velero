echo '-------Deploy Velero for GKE Backup (typically in 1 min)'
starttime=$(date +%s)
. ./setenv.sh

echo "-------Download and Install verlero CLI if needed"
if [ ! -f ~/gke-casa/velero ]; then
  wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
  tar -zxvf velero-v1.12.0-linux-amd64.tar.gz
  sudo mv velero-v1.12.0-linux-amd64/velero ~/gke-casa
  sudo rm velero-v1.12.0-linux-amd64.tar.gz
  sudo rm -rf velero-v1.12.0-linux-amd64
fi

echo "-------Create a GCS storage bucket if not exist"
cat gke-demo-back
if [ `echo $?` -eq 1 ];then
  echo $MY_BUCKET-$(date +%d%H%M%s) > bucket4velero1
  gsutil mb gs://$(cat bucket4velero1)/
fi

echo "-------Create a service account for velero"
sudo gcloud iam service-accounts list | grep abrahamarumbaka
if [ `echo $?` -eq 1 ];then
  export MY_PROJECT_ID=$(gcloud config get-value project)
  MY_GSA_NAME=abrahamarumbaka

 sudo gcloud iam service-accounts create $MY_GSA_NAME \
    --display-name "Velero service account"

  MY_SERVICE_ACCOUNT_EMAIL=$(sudo gcloud iam service-accounts list \
    --filter="displayName:Velero service account" \
    --format 'value(email)')

  ROLE_PERMISSIONS=(
    compute.disks.get
    compute.disks.create
    compute.disks.createSnapshot
    compute.snapshots.get
    compute.snapshots.create
    compute.snapshots.useReadOnly
    compute.snapshots.delete
    compute.zones.get
    storage.objects.create
    storage.objects.delete
    storage.objects.get
    storage.objects.list
    iam.serviceAccounts.signBlob
  )

  sudo gcloud iam roles list --project $MY_PROJECT_ID | grep Velero
  if [ `echo $?` -eq 1 ];then
    sudo gcloud iam roles create velero.server \
      --project $MY_PROJECT_ID \
      --title "Velero Server" \
      --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"
  fi

  sudo gcloud projects add-iam-policy-binding $MY_PROJECT_ID \
    --member serviceAccount:$MY_SERVICE_ACCOUNT_EMAIL \
    --role projects/$MY_PROJECT_ID/roles/velero.server

  sudo gsutil iam ch serviceAccount:$MY_SERVICE_ACCOUNT_EMAIL:objectAdmin gs://$(cat bucket4velero1)

  sudo gcloud iam service-accounts keys create abrahamsa4velero1 \
    --iam-account $MY_SERVICE_ACCOUNT_EMAIL
fi

echo "-------Install velero using the SA"
sudo velero install \
    --provider gcp \
    --plugins velero/velero-plugin-for-gcp:v1.6.0 \
    --bucket $(cat bucket4velero1) \
    --use-node-agent \
    --uploader-type restic \
    --secret-file ./abrahamsa4velero1

# --features=EnableCSI \
#     --plugins velero/velero-plugin-for-gcp:v1.6.0,velero/velero-plugin-for-csi:v0.3.0 \

echo "-------One time On-Demand Backup of yong-postgresql namespace"
sudo kubectl wait --for=condition=ready --timeout=180s -n velero pod -l component=velero
sudo velero backup create yong-postgresql-backup --include-namespaces yong-postgresql

echo "-------Hourly scheduled backup of yong-postgresql namespace"
sudo kubectl create -f velero-schedule.yaml

endtime=$(date +%s)
duration=$(( $endtime - $starttime ))
echo "" | awk '{print $1}'
echo "-------Total time to enable Velero backup for GKE is $(($duration / 60)) minutes $(($duration % 60)) seconds."
echo "" | awk '{print $1}'
echo "-------Created by Yongkang"
echo "-------Email me if any suggestions or issues he@yongkang.cloud"
echo "" | awk '{print $1}'
