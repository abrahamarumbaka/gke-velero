echo '-------Deploy Velero for GKE Backup (typically in 1 min)'
starttime=$(date +%s)
. ./setenv.sh
$MY_PROJECT_ID='solar-bebop-431805-c9'
$MY_SERVICE_ACCOUNT_EMAIL='velero@solar-bebop-431805-c9.iam.gserviceaccount.com'
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


