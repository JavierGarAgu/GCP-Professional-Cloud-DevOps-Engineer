LAB COMMANDS
```
gcloud container clusters get-credentials sli-lab --zone europe-west1-b

kubectl get nodes

kubectl get pods -A

kubectl get pods -n production

kubectl get svc -n production

kubectl get deployments -n production

kubectl get configmap -n production

kubectl describe svc nginx -n production

kubectl describe pod -n production -l app=homepage

kubectl logs deployment/homepage -n production

kubectl logs deployment/nginx -n production

kubectl exec -it deployment/nginx -n production -- sh

wget -qO- http://homepage:3000

exit

curl http://IP

curl http://IP

curl http://IP

$good=0;$total=100;1..100|%{$l=[int]((curl.exe -s http://104.155.109.144) -replace '\D','');if($l -lt 100){$good++}};"Good Requests: $good";"Total Requests: $total";"SLI: $([math]::Round(($good/$total)*100,2))%"
```
![](../../doc/images/25.PNG)




