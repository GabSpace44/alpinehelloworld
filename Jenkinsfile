// Pipeline pour le Lab-3: Test d'acceptance (Version Pont Dynamique)
pipeline {
    agent any

    // 1. Définition des paramètres
    parameters {
        string(name: 'REPO_URL', defaultValue: 'https://github.com/GabSpace44/alpinehelloworld', description: 'URL du dépôt Git à cloner.')
        string(name: 'IMAGE_NAME', defaultValue: 'test-acceptance-image', description: 'Nom de l\'image Docker.')
        string(name: 'IMAGE_TAG', defaultValue: 'latest-test', description: 'Tag (version) de l\'image Docker.')
        string(name: 'CONTAINER_NAME', defaultValue: 'acceptance-test-container', description: 'Nom du conteneur à démarrer.')
        
        // Mappage de port (Hôte:Conteneur)
        string(name: 'PORT_MAPPING', defaultValue: '8090:5000', description: 'Mappage de port Hôte:Conteneur.')
        
        // NOTE: On retire TEST_URL des paramètres fixes car on va la calculer dynamiquement
        // ENDPOINT API DEPLOYMENT
       string(name: 'STG_API_ENDPOINT',defaultValue: 'http://127.0.0.1:1993/',description: 'Staging API.')
       string(name: 'STG_APP_ENDPOINT',defaultValue: 'http://127.0.0.1:80/',description: 'Staging API.')

    }
    
    stages {
        
        stage('📥 Clonage du Dépôt') {
            steps {
                cleanWs()
                git url: params.REPO_URL, branch: 'master'
                echo "Dépôt ${params.REPO_URL} cloné."
            }
        }

        stage('🔨 Build de l\'Image') {
            steps {
                script {
                    def fullImageName = "gabriel45/${params.IMAGE_NAME}:${params.IMAGE_TAG}"
                    
                    // Build de l'image
                    sh "docker build -t ${fullImageName} ."
                    echo "Image construite : ${fullImageName}"
                    
                    env.FULL_IMAGE_NAME = fullImageName
                }
            }
        }
        
        stage('🐳 Démarrage du Conteneur') {
            steps {
                script {
                    def containerName = params.CONTAINER_NAME
                    def imageToRun = env.FULL_IMAGE_NAME 

                    // Nettoyage
                    sh "docker rm -f ${containerName} || true" 
                    
                    // Lancement SANS forcer le réseau bridge. On laisse Docker choisir.
                    // On garde le port mapping pour que l'hôte (la passerelle) puisse rediriger le trafic.
                    sh "docker run -d --name ${containerName} -p ${params.PORT_MAPPING} -e PORT=5000 ${imageToRun}"
                    
                    // Vérifications visuelles
                    sh "docker ps"
                    sh "docker logs ${containerName}"
                    
                    echo "⏳ Attente de 15 secondes pour le démarrage complet..."
                    sleep 15 
                }
            }
        }
        
        stage('✅ Test d\'Acceptance HTTP') {
            steps {
                script {
                    // --- CRÉATION DU PONT (Calcul de l'IP Gateway) ---
                    // 1. On récupère l'IP actuelle de Jenkins (ex: 172.17.0.5 ou 10.0.0.4)
                    // La commande 'hostname -i' fonctionne sur 99% des images Linux
                    def jenkinsIp = sh(returnStdout: true, script: "hostname -i | awk '{print \$1}'").trim()
                    
                    // 2. On remplace le dernier segment par .1 pour trouver la passerelle (L'Hôte)
                    // Ex: 10.0.0.4 devient 10.0.0.1
                    def gatewayIp = jenkinsIp.tokenize('.')[0..2].join('.') + '.1'
                    
                    echo "📍 IP Jenkins: ${jenkinsIp}"
                    echo "🌉 Pont vers l'Hôte (Gateway): ${gatewayIp}"

                    // 3. On reconstruit l'URL avec cette IP dynamique
                    def port = params.PORT_MAPPING.split(':')[0]
                    def dynamicUrl = "http://${gatewayIp}:${port}"
                    def fullImageName = "gabriel45/${params.IMAGE_NAME}:${params.IMAGE_TAG}"
                    echo "🔍 Tentative de connexion sur le pont : ${dynamicUrl}"
                    
                    // Test officiel
                    httpRequest customHeaders: [[maskValue: false, name: 'User-Agent', value: 'Jenkins-CI']], 
                                url: dynamicUrl, 
                                httpMode: 'GET',
                                validResponseCodes: '200' 
                    
                    echo "✅ SUCCÈS ! Jenkins a traversé le pont vers ${dynamicUrl}"
                }
            }
        }

           stage('🧹 Nettoyage') {
            steps {
                echo "Arrêt du conteneur de test..."
                sh "docker rm -f ${params.CONTAINER_NAME} || true"
            }
        }


            stage('✅ APPEL API STAGING') {
            steps {
                script {
                    // --- CRÉATION DU PONT (Calcul de l'IP Gateway) ---
                    // 1. On récupère l'IP actuelle de Jenkins (ex: 172.17.0.5 ou 10.0.0.4)
                    // La commande 'hostname -i' fonctionne sur 99% des images Linux
                    def jenkinsIp = sh(returnStdout: true, script: "hostname -i | awk '{print \$1}'").trim()
                    
                    // 2. On remplace le dernier segment par .1 pour trouver la passerelle (L'Hôte)
                    // Ex: 10.0.0.4 devient 10.0.0.1
                    def gatewayIp = jenkinsIp.tokenize('.')[0..2].join('.') + '.1'
                    
                    echo "📍 IP Jenkins: ${jenkinsIp}"
                    echo "🌉 Pont vers l'Hôte (Gateway): ${gatewayIp}"

                    // 3. On reconstruit l'URL avec cette IP dynamique
                    def port = params.PORT_MAPPING.split(':')[0]
                    def dynamicUrl = "http://${gatewayIp}:1993/staging"
                    sh """
                    curl -X POST ${dynamicUrl} -H 'Content-Type: application/json' -d '{"your_name":"gabriel45","container_image":${FULL_IMAGE_NAME}, "external_port":"80", "internal_port":"80"}'
                    """
                }
            }
        }

    

     
    }
}
