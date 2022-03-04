def  previous_result = currentBuild.getPreviousBuild().result
pipeline {

  options {
      disableConcurrentBuilds()
      buildDiscarder(logRotator(numToKeepStr: '15'))
      timeout(time: 1, unit: 'HOURS')
   }

  environment {
     PROJECT_NAME_ON_GIT = env.GIT_URL.replaceAll('https://<url>/', '').replaceAll('.git', '')   
     PROJECT_NAME = "${env.GIT_BRANCH}-${PROJECT_NAME_ON_GIT}"
     SHORT_COMMIT_ID = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
     POM_VERSION = readMavenPom().getVersion()
     IMAGE_VERSION = "${POM_VERSION}-${SHORT_COMMIT_ID}"
     GIT_COMMITTER_EMAIL = sh(script: "git --no-pager show -s --format='%ae'", returnStdout: true).trim()
     GIT_COMMITER_NAME= sh(script: "git --no-pager show -s --format='%an'", returnStdout: true).trim()
     JOB_TRIGGER_EMAIL = emailextrecipients([ [$class: 'RequesterRecipientProvider'] ])
     RECIPIENTS = "${GIT_COMMITTER_EMAIL}
     NAMESPACE = "<namespace>"	
     REPLICA  = "<replica>" 
     NEW_COMMITIDSHORT = sh(returnStdout: true, script: "git log -n 1 --pretty=format:'%h'").trim()
     NEW_COMMITIDLONG = sh(returnStdout: true, script: "git rev-parse HEAD").trim()
     NEW_COMMIT_DATE = sh(returnStdout: true, script: "git log -1 --format=%cd").trim()
     NPM_REGISTRY  = "<NPM_REGISTRY>"
     ARTIFACTORY_REGISTRY  = "<ARTIFACTORY_REGISTRY>"
     ARTIFACTORY_CREDENTIALS = 'artifact_credentials'     
   } 

   
  agent { label '<agent>' }	

  stages {
 
    stage ('Inital') {
      steps {
          
          script {
             wrap([$class: 'BuildUser']) {
             USER_ID = "${BUILD_USER}"
             echo "previous build result is ${previous_result}"
             echo "git branch is that ${env.GIT_BRANCH} "
             echo "PROJECT NAME is ${PROJECT_NAME}"
             echo "RECIPIENTS are ${env.RECIPIENTS}"
             echo "NEW_COMMITIDSHORT  is that ${env.NEW_COMMITIDSHORT} "
             echo "NEW_COMMITIDLONG NAME is ${NEW_COMMITIDLONG}"
             echo "NEW_COMMIT_DATE are ${env.NEW_COMMIT_DATE}"
             echo "JOB_TRIGGER_EMAIL is ${JOB_TRIGGER_EMAIL}"
             echo "GIT_COMMITTER_EMAIL is ${GIT_COMMITTER_EMAIL}"
             echo "GIT_COMMITER_NAME is ${env.GIT_COMMITER_NAME}"
             echo "BUILD_USER is ${env.BUILD_USER}"
             echo "BUILD_USER MAIL is ${env.BUILD_USER_EMAIL }"
             echo "REPLICA is ${REPLICA}"
             echo "SHORT COMMIT ID is  ${SHORT_COMMIT_ID}"
             echo "POM VERSION is ${POM_VERSION}"
             echo "IMAGE VERSION is ${IMAGE_VERSION}"
             echo "JENKINS_URL is that ${env.JENKINS_URL}"
             sh  """ 
             mkdir -p ${env.Workspace}/scripts 
             """
             dir("${env.Workspace}/scripts") {
               git ( branch: 'master',
               credentialsId: 'credentialsId',
               url: 'url' )
          

             sh  """ 
             mkdir -p ${env.Workspace}/properties 
             """

           dir("${env.Workspace}/properties") {
           git ( branch: 'master',
               credentialsId: 'credentialsId',
               url: 'url' )
           }
           

        
      }
    }
    }
    }


     stage('Add secret if there is exist on git') {
      steps {
        script {
       dir("${env.Workspace}/properties/${env.GIT_BRANCH}") {
       if (fileExists("${PROJECT_NAME_ON_GIT}")) {
       openshift.withCluster("OCP") {
       openshift.withProject("${NAMESPACE}") {
       openshift.apply(openshift.raw("create secret generic  ${PROJECT_NAME} --dry-run=true --from-file=application.properties=${PROJECT_NAME_ON_GIT} --output=yaml").actions[0].out) 
       }
       }        
       } else {
         echo "There is no secret on git for  ${PROJECT_NAME_ON_GIT}"
       }
      }
      }
      }
      }





      stage('Create and edit version.json') {
      steps {
        script {

      dir("${env.Workspace}") {

        sh """
        cp -rfp ${env.Workspace}/scripts/devops/version.json  ${env.Workspace}/src/main/resources/
        ls -lah ${env.Workspace}/src/main/resources/
        cat ${env.Workspace}/src/main/resources/version.json
        """

          contentReplace(
       configs: [
           fileContentReplaceConfig(
               configs: [
                   fileContentReplaceItemConfig(
                       search: 'LONGCOMMITID',
                       replace: "${env.NEW_COMMITIDLONG}")
                   ],
               fileEncoding: 'UTF-8',
               filePath: "${env.Workspace}/src/main/resources/version.json")
        ])               


       contentReplace(
       configs: [
           fileContentReplaceConfig(
               configs: [
                   fileContentReplaceItemConfig(
                       search: 'SHORTCOMMITID',
                       replace: "${env.NEW_COMMITIDSHORT}")
                   ],
               fileEncoding: 'UTF-8',
               filePath: "${env.Workspace}/src/main/resources/version.json")
        ]) 
       contentReplace(
       configs: [
           fileContentReplaceConfig(
               configs: [
                   fileContentReplaceItemConfig(
                       search: 'VERSION',
                       replace: "${env.POM_VERSION}")
                   ],
               fileEncoding: 'UTF-8',
               filePath: "${env.Workspace}/src/main/resources/version.json")
        ]) 



       contentReplace(
       configs: [
           fileContentReplaceConfig(
               configs: [
                   fileContentReplaceItemConfig(
                       search: 'BUILDTIME',
                       replace: "${env.NEW_COMMIT_DATE}")
                   ],
               fileEncoding: 'UTF-8',
               filePath: "${env.Workspace}/src/main/resources/version.json")
        ]) 


              sh """
               ls  ${env.Workspace}/src/main/resources/
               pwd
               cat  ${env.Workspace}/src/main/resources/version.json 
               """

        }}}}

      stage('Npm build') {
      steps {
        script {
         if(fileExists("${env.Workspace}/webfrontend"))
         {
           withCredentials([usernamePassword(
            credentialsId: env.ARTIFACTORY_CREDENTIALS,
            usernameVariable: 'ARTIFACTORY_USERNAME',
            passwordVariable:  'ARTIFACTORY_USERNAME',
          )]) { 
          nodejs(nodeJSInstallationName: 'Node12') {
              
          sh """
            export http_proxy=<proxy-url>
            export https_proxy=<proxy-url>
            export HTTP_PROXY=<proxy-url>
            export HTTPS_PROXY=<proxy-url>
            npm config set proxy http://<proxy-url>
            npm config set https-proxy  http://<proxy-url>
            curl -u$ARTIFACTORY_USERNAME:$ARTIFACTORY_USERNAME ${ARTIFACTORY_REGISTRY}/api/npm/auth  >> $HOME/.npmrc
            npm ci --registry ${NPM_REGISTRY} 

          """} 

          nodejs(nodeJSInstallationName: 'Node12') {sh """ npm run-script build """} 
          }

          }
         } else {
           echo "there is no webfrontend folder inside webfrontend"
         }

        }
      }
        }

    stage('Build') {
      steps {
        script {
          configFileProvider([configFile(fileId: '<fileId>', variable: 'MAVEN_SETTINGS')]) {
          sh """
          cd ${env.Workspace}

          chmod +x mvnw
         ./mvnw -s $MAVEN_SETTINGS -Dhttp.proxyHost=<proxy-url> -Dhttp.proxyPort=3128 -Dhttps.proxyHost=<proxy-url> -Dhttps.proxyPort=3128 install   
          mkdir tmp
          cp target/${env.PROJECT_NAME_ON_GIT}*.war tmp/${env.PROJECT_NAME_ON_GIT}.war
          """
          // try catch for test purposes it will be disabled in real usage and declerative pipeline throw exception
          //  try {    

         }


       echo "JENKINS_URL is that ${env.JENKINS_URL}"
       if ("${env.JENKINS_URL}" == 'https://<jenkinsold-url>/'){

       sh """ 
       cp -rfp ${env.Workspace}/scripts/devops/Dockerfile tmp/Dockerfile  
       cat tmp/Dockerfile
        """
       REGISTRY_URL = "REGISTRY_URL"
       FQDN  = "FQDN"
       RECIPIENTS = "${GIT_COMMITTER_EMAIL}, <additonal-email>
       
       } else if ("${env.JENKINS_URL}" == 'https://<jenkinsnew-url>/')  { 

       sh """ 
       cp -rfp ${env.Workspace}/scripts/devops/Dockerfile.v2maven tmp/Dockerfile  
       cat tmp/Dockerfile 
       """      
       REGISTRY_URL = "REGISTRY_URL"
       FQDN  = "FQDN"
       RECIPIENTS = "${GIT_COMMITTER_EMAIL}, <additonal-email>   


       } else {

         echo "JENKINS_URL has not been recognized"
       }
       echo "REGISTRY_URL is that ${REGISTRY_URL}"
       echo "FQDN is that ${FQDN}"
       echo "RECIPIENTS is that ${RECIPIENTS}"





          contentReplace(
           configs: [
               fileContentReplaceConfig(
                   configs: [
                       fileContentReplaceItemConfig(
                           search: 'WAR_NAME',
                           replace: "${env.PROJECT_NAME_ON_GIT}")
                       ],
                   fileEncoding: 'UTF-8',
                   filePath: "${env.Workspace}/tmp/Dockerfile")
            ])
           
          sh """ cat  ${env.Workspace}/tmp/Dockerfile  """


			     openshift.withCluster("OCP") {
           openshift.withProject("${NAMESPACE}") {
           def buildexistence = openshift.selector("bc", "${PROJECT_NAME}").exists()
           echo "build config is exist: ${buildexistence}"
           if ("${buildexistence}" == 'true'){

              openshift.startBuild("${PROJECT_NAME}" ,"--from-dir=${env.Workspace}/tmp", "--wait=true","--follow=true")

           } else if ("${buildexistence}" == 'false') { 

            openshift.newBuild("--name=${PROJECT_NAME}", "--strategy=docker", "--binary=true")
            openshift.startBuild("${PROJECT_NAME}" ,"--from-dir=${env.Workspace}/tmp", "--wait=true","--follow=true")

            } else  {
                  echo "build config is existence is different than true or false ${buildexistence}"
                  currentBuild.result = 'FAILED'

           }
             // tag image from latest to the commit ıd for better tracking in the future
            openshift.tag( "${NAMESPACE}/${PROJECT_NAME}:latest", "${NAMESPACE}/${PROJECT_NAME}:${IMAGE_VERSION}")

           if ("${env.JENKINS_URL}" == 'https://<jenkinsold-url>/'){

            echo "----------------Build verification starting----------------"
          
            def builds = openshift.selector('bc', "${PROJECT_NAME}")related("builds")
            
			      timeout(10) { 
                  builds.watch {
                  if ( it.count() == 0 ) return false
                  def allDone = true
                  it.withEach {
                      def buildModel = it.object()
                      if ( it.object().status.phase != "Complete" ) {
                          allDone = false
                      }
                  }
      
                  return allDone;
                    }
			       }
           echo "----------------Build verification is done with success ----------------"
       } else if ("${env.JENKINS_URL}" == 'https://<jenkinsnew-url>/')  { 

           echo "this is v2 jenkins"

       } else {
           echo "there is something wrong"
       }

           }
           } 
          //  }catch ( Exception e ) { echo "Error encountered: ${e}"	 }
        }
        }
      }
     

    stage('Deployment') {
      steps {
        script {
          // try catch for test purposes it will be disabled in real usage and declerative pipeline throw exception
          //  try {

           if ("${env.JENKINS_URL}" == 'https://<jenkinsold-url>/'){
    
               templatePath  = "${env.Workspace}/scripts/devops/openshift_template.yaml"
    
           } else if ("${env.JENKINS_URL}" == 'https://<jenkinsnew-url>/')  { 
    
               templatePath  = "${env.Workspace}/scripts/devops/openshift_templatev2.yaml"
    
           } else {
    
              echo "JENKINS_URL has not been recognized"
           }

           echo "templatePath is ${templatePath}"
           echo "REGISTRY_URL is that ${REGISTRY_URL}"
           
           openshift.withCluster('OCP') {
				   openshift.withProject("${NAMESPACE}"){
           def template = openshift.process(readFile(file: templatePath ), "-p", "NAMESPACE=${NAMESPACE}", "-p", "REGISTRY_URL=${REGISTRY_URL}", "-p", "FQDN=${FQDN}", "-p", "PROJECT_NAME=${PROJECT_NAME}", "-p", "REPLICA=${REPLICA}", "-p", "IMAGE_TAG=${IMAGE_VERSION}")
          //  def template = openshift.process(readFile(file: templatePath )) // read static template just for test purposes
            echo "-------------------------------TEMPLATE WİLL BE PRESENTED İN BELOW-----------------------------------------"
           	echo "${template}"
            echo "--------------------------------TEMPLATE HAS BEEN PRESENTED ON ABOVE----------------------------------------"
            def deployment = openshift.apply(template)

          //  }catch ( Exception e ) { echo "Error encountered: ${e}"	 } 
        
        }
        }
        }
        }
        }

     stage('Verifications') {
      steps {
        script {
          timeout(10) {

          openshift.withCluster('OCP') {
          openshift.withProject("${NAMESPACE}") {
          echo "---------Secret is checking-----------"
          
          dir("${env.Workspace}/scripts/configurations/${env.GIT_BRANCH}") {
           if (fileExists("${PROJECT_NAME_ON_GIT}")) {

          def secretexist = openshift.selector('secret', "${PROJECT_NAME}")exists()
          if (!secretexist) {
          echo "secret ${PROJECT_NAME} is not exist"
          currentBuild.result = 'FAILED'
          } else {
          echo "secret ${PROJECT_NAME} is exist"
          }
           }
           else {
             echo "There is no secret in git"
           }
          }

          echo "---------Secret is checked-----------"

          echo "---------Deployment is checking-----------"


            def dc = openshift.selector('dc', "${PROJECT_NAME}")
            dc.rollout().status()
           
            echo "---------Deployment is checked-----------"

            echo "-------- Service is checking.............."

            timeout(10){
            waitUntil {

            def connected = openshift.verifyService("${PROJECT_NAME}")
            echo "${connected}"
            if (connected) {
                echo "Able to connect to ${PROJECT_NAME} service"
                return true
            } else {
                echo "Unable to connect to ${PROJECT_NAME} service"
                return false
            }
            }
            }
            echo "-------- Service is checked.............."

            echo "-------- Route is Checking.............."

            // def routedescribe = openshift.selector( 'route', "${PROJECT_NAME}").describe() // Just for describe route. No need in real usage just for test purposes
            // echo "routedescribe is  ${routedescribe}"  // echo above class
            def routestatus = openshift.selector( 'route', "${PROJECT_NAME}").object().status
            echo "Detailed Routestatus is  ${routestatus}"
            def host=  routestatus.ingress.host
            echo "URL is  ${host}"
            def laststatus=  routestatus.ingress.conditions.status
            if ("${laststatus}" == '[[True]]') {
                echo "route status is True "
            } else if ("${laststatus}" == '[[False]]')  {
                echo "route status is  False. You need to check."
                currentBuild.result = 'FAILED'
            } else {
              echo "route status is  ${laststatus}. You need to check why it is neither True nor False"
              currentBuild.result = 'FAILED'
            }

            echo "-------- Route is Checked.............."

            }
           }
        }
        }
        }
        }
  }
      post {
      failure {
      script{
      wrap([$class: 'BuildUser']) {
      emailext ( 
      body: '''${SCRIPT, template="groovy-html.template"}''',
      mimeType: 'text/html',
      attachLog: true,
      to: RECIPIENTS, 
      subject: "FAILED: Job ${env.JOB_NAME} ${env.BUILD_NUMBER}  that code last commited by ${env.GIT_COMMITER_NAME}" 
      )
      }
      }
      }
     success {
      script {
      if ( "${previous_result}" == "FAILURE") {
      wrap([$class: 'BuildUser']) {
      emailext (
      body: '''${SCRIPT, template="groovy-html.template"}''',
      attachLog: true,
      to: RECIPIENTS, 
      subject: "SUCCESS: Job ${env.JOB_NAME} ${env.BUILD_NUMBER} that code last commited by ${env.GIT_COMMITER_NAME} after failed builed" 
      )
      }
        } else {
            echo 'Previous build is not failure and current build is success !'
        }
      }
      }
      always {
         cleanWs()
         dir("${env.WORKSPACE}@tmp") {deleteDir()}
      }
      } 
      }
  