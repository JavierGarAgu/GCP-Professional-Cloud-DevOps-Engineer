for git repos problems

choco install git-filter-repo (powershell with admin rights)
git filter-repo --path "problem path" --invert-paths --force
git remote -v
git remote add origin https://github.com/JavierGarAgu/GCP-Professional-Cloud-DevOps-Engineer.git
git push --force-with-lease origin dev