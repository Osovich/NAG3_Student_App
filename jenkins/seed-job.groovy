// Jenkins Seed Job for NAG3 Student App
// This script creates the main pipeline job

pipelineJob('nag3-student-app-pipeline') {
    description('NAG3 Student App CI/CD Pipeline')
    
    properties {
        githubProjectUrl('https://github.com/your-org/nag3-student-app')
    }
    
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/your-org/nag3-student-app.git')
                        credentials('github-token')
                    }
                    branch('*/main')
                }
            }
            scriptPath('Jenkinsfile')
        }
    }
    
    triggers {
        githubPush()
        pollSCM('H/5 * * * *') // Poll every 5 minutes
    }
    
    parameters {
        stringParam('BRANCH', 'main', 'Git branch to build')
        choiceParam('ENVIRONMENT', ['test', 'staging', 'production'], 'Target environment')
        booleanParam('SKIP_TESTS', false, 'Skip running tests')
        booleanParam('FORCE_DEPLOY', false, 'Force deployment even if tests fail')
    }
    
    configure {
        it / 'properties' / 'org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty' / 'triggers' / 'hudson.triggers.SCMTrigger' {
            'spec'('H/5 * * * *')
        }
    }
}
