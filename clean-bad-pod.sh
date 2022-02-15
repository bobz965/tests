kubectl get pod -A -o wide  | grep -v Running | grep -v NAME | awk '{print "kubectl delete pod -n" $1 " " $2 }' | bash -x
