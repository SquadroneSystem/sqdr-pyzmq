env.setProperty('GIT_REPOSITORY', 'sqdr-pyzmq')

Map nodes = [
    "amd64/ubuntu/focal": "ec2-fleet-amd64",
    "armhf/raspbian/buster": "ec2-fleet-arm64"
]

Map tasks = [:]

// for each example: https://gist.github.com/oifland/ab56226d5f0375103141b5fbd7807398
nodes.each { build_arch, label ->
    tasks[build_arch] = {
        node(label) {
            try {
                stage('Checkout SCM') {
                    if (env.CHANGE_BRANCH) {
                        env.setProperty('BRANCH_NAME', env.CHANGE_BRANCH)
                    }
                    cleanWs()
                    echo "Checking out ${env.GIT_REPOSITORY}"
                    checkout([$class: 'GitSCM', branches: [[name: "${env.BRANCH_NAME}"]], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'SubmoduleOption', disableSubmodules: false, parentCredentials: true, recursiveSubmodules: true, reference: '', trackingSubmodules: false], [$class: 'CloneOption', noTags: false, reference: '', shallow: true]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'ci-squadrone', url: "git@github.com:SquadroneSystem/${env.GIT_REPOSITORY}.git"]]])
                }

                stage('Environment Initialization') {
                    def git_commit = sh (script: 'git rev-parse HEAD', returnStdout: true).trim()
                    env.setProperty('GIT_COMMIT', git_commit)
                    env.setProperty('ACCESS_TOKEN', "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")
                    stage('Notify GitHub build start') {
                        sh "ci/notify_github $GIT_REPOSITORY $GIT_COMMIT $ACCESS_TOKEN $BUILD_URL pending"
                    }

                    env.setProperty('BUILD_ARCH', build_arch)
                }

                stage('Create deb packages') {
                    if (env.BRANCH_NAME == 'main') {
                        echo "Building main branch"
                        sh "PATH=/opt/sqdr/ssap/bin:$PATH \
                            jenkins-multi-venv.sh \
                                --build $BUILD_ARCH"
                    } else {
                        echo "Building test ${env.BRANCH_NAME}, packages will not be uploaded to apt repository"
                        sh "SSAP_JENKINS_DISABLE_DPUT=1 \
                            PATH=/opt/sqdr/ssap/bin:$PATH \
                            jenkins-multi-venv.sh \
                                --build $BUILD_ARCH"
                    }
                }

                stage('Archive build') {
                    echo "Archive artifacts:"
                    archiveArtifacts artifacts: "**/*jenkins${BUILD_NUMBER}*.deb", followSymlinks: true
                }
            } catch (e) {
                echo "Error: ${e}"
                echo "Failed to build deb packages"
                throw e
            } finally {
                stage('Notify result') {
                    def currentResult = currentBuild.result ?: 'SUCCESS'
                    if (currentResult == 'UNSTABLE') {
                        echo "Build is unstable"
                    }

                    if (currentResult == 'SUCCESS') {
                        echo "Finished building deb packages"
                        sh "ci/notify_github $GIT_REPOSITORY $GIT_COMMIT $ACCESS_TOKEN $BUILD_URL success"
                    } else {
                        echo "Failed to build deb packages"
                        sh "ci/notify_github $GIT_REPOSITORY $GIT_COMMIT $ACCESS_TOKEN $BUILD_URL failure"
                    }

                    def previousResult = currentBuild.getPreviousBuild()?.result
                    if (previousResult != null && previousResult != currentResult) {
                        echo "Build result changed from ${previousResult} to ${currentResult}"
                    }
                }

                stage('Clean workspace') {
                    cleanWs()
                }
            }
        }
    }
}

parallel(tasks)
