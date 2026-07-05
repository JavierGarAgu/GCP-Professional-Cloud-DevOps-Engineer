# test that the site is healthy
curl http://35.240.72.241

# start the incident
curl http://35.240.72.241/start-incident

# test if now respond with HTTP 500
curl -i http://35.240.72.241

# finish the incident
curl http://35.240.72.241/end-incident

# verify that the service is healthy again
curl http://35.240.72.241

PostMortem example
https://sre.google/sre-book/example-postmortem/

It is the official example from the Google SRE Book. Although the incident is fictional (the Shakespeare search service), it shows exactly how Google expects an SRE team to write a blameless postmortem.

The postmortem follows a clear structure:

Summary – What happened?
Impact – Who or what was affected?
Root Cause – Why did it happen?
Trigger – What started the incident?
Detection – How was the problem detected?
Resolution – How was the issue fixed?
Action Items – What improvements will prevent it from happening again?
Lessons Learned – What went well, what went wrong, and what can be improved.
Timeline – A chronological list of the events during the incident.

The most important idea is that it is blameless.

It does not:

Blame a person.
Name who made the mistake.
Focus on punishment.

Instead, it focuses on learning from the incident and improving the system.

Applying it to my lab

In my Node.js lab, the postmortem could look like this:

Summary: The application started returning HTTP 500 errors.
Impact: Users could not access the application for several minutes.
Trigger: The incident was triggered by calling /start-incident.
Detection: Monitoring or a health check detected the increase in HTTP 500 responses.
Resolution: The incident was resolved by calling /end-incident.
Action Items: Add monitoring, alerts, health checks, automatic recovery, and better documentation.

The correct answer is B because SRE is not only about fixing incidents—it is also about sharing knowledge across the engineering organization

if you only share the document with the manager that limits the learning to a single person or team.

In SRE, incidents are considered learning opportunities for the entire engineering organization, so restricting the postmortem to one manager goes against that principle.