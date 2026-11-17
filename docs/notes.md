## The biggest Docker problem you faced and how you solved it
**Problem:** `docker compose up -d --build` finished building both images successfully, but the `api` container failed its healthcheck (`dependency failed to start: container payapp-api is unhealthy`) and the website never started. Because the build passed, the error only showed up at runtime. Reading `docker logs payapp-api` revealed two errors, one after the other:

1. `Error: Cannot find module '../src/aws-exports'`
2. `TypeError: Cannot read properties of undefined (reading 'Cognito')`

The backend imports an AWS Amplify configuration file (`src/aws-exports`) that is not stored in the repository, because it is normally generated for each developer's own AWS account. The demo does not need AWS, but Node.js refuses to start without that file, and then the code reads `Auth.Cognito.userPoolId` from it.

**Solution:** in the `api` stage of the `Dockerfile` I create a small placeholder `src/aws-exports.js` (only when the file does not already exist) containing empty Cognito values. After that, the server started and the healthcheck became `healthy`.




## The most important Git/GitHub lesson you learned in this assignment
that how evrey project has it's won docker configurations and how to deal with them ,
A cloned project still points to the original author's repository through `origin`
how to pull request and merge two branches together  I did all the Docker work on 
a separate branch (`feature/docker-setup`), pushed it to GitHub, opened a Pull Request into
 `master`, and merged it. This keeps `master` clean and shows the whole change in one place before it is merged.


