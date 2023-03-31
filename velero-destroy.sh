echo '-------Remove Velero for GKE and Clean up (typically in 3 mins)'
starttime=$(date +%s)
. ./setenv.sh

velero uninstall --force
sudo rm /usr/local/bin/velero
gsutil rm -r gs://$(cat bucket4velero1) -f
rm bucket4velero1
gcloud iam service-accounts delete $(gcloud iam service-accounts list | grep vsa4yong1 | awk '{print $2}') -q

endtime=$(date +%s)
duration=$(( $endtime - $starttime ))
echo "" | awk '{print $1}'
echo "-------Total time to build a GKE cluster with PostgreSQL is $(($duration / 60)) minutes $(($duration % 60)) seconds."
echo "" | awk '{print $1}'
echo "-------Created by Yongkang"
echo "-------Email me if any suggestions or issues he@yongkang.cloud"
echo "" | awk '{print $1}'