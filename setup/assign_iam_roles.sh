#!/bin/bash -e

# author: Ole Schuett

PROJECT=$(gcloud config list --format 'value(core.project)')
PROJECT_NUMBER=$(gcloud projects describe ${PROJECT} --format 'value(projectNumber)')

CLOUDBUILD_ACCOUNT="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
FRONTEND_ACCOUNT="cp2kci-frontend@${PROJECT}.iam.gserviceaccount.com"
BACKEND_ACCOUNT="cp2kci-backend@${PROJECT}.iam.gserviceaccount.com"

set -x

# frontend
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:${FRONTEND_ACCOUNT}" --role="roles/pubsub.publisher"      # for sending message to backend
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:${FRONTEND_ACCOUNT}" --role="roles/storage.objectViewer"  # for docker image download

# backend / toolbox
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:${BACKEND_ACCOUNT}" --role="roles/pubsub.subscriber"      # for backend to receiving messages from frontend
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:${BACKEND_ACCOUNT}" --role="roles/pubsub.publisher"       # for toolbox to send messsages to backend
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:${BACKEND_ACCOUNT}" --role="roles/storage.admin"          # for toolbox to upload docker images

# cloud builder
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:${CLOUDBUILD_ACCOUNT}" --role="roles/compute.instanceAdmin"   # for updating frontend container
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:${CLOUDBUILD_ACCOUNT}" --role="roles/container.developer"     # for updating backend container
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:${CLOUDBUILD_ACCOUNT}" --role="roles/iam.serviceAccountUser"  # somehow required too

#EOF
