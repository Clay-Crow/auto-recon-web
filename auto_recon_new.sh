#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


# Fonction pour exécuter les tâches
run_task() {
    local task_name="$1"
    local command="$2"
    local output_file="/tmp/task_$$.log"
    
    echo -ne "${YELLOW}${task_name}... [${NC}"
    
    eval "$command" > "$output_file" 2>&1 &
    local pid=$!
    
    while kill -0 "$pid" 2>/dev/null; do
        echo -ne "${GREEN}▓${NC}"
        sleep 0.3
    done
    
    wait "$pid"
    local status=$?
    
    echo -e "${YELLOW}] ${GREEN}✓ Terminé${NC}"
    
    if [ $status -eq 0 ] && [ -s "$output_file" ]; then
        echo -e "\n${CYAN}── Résultats ─────────────────────────────${NC}"
        head -n 5 "$output_file"
        [ $(wc -l < "$output_file") -gt 5 ] && echo "... (voir fichier complet pour plus de détails)"
        echo -e "${CYAN}──────────────────────────────────────────${NC}"
    elif [ $status -ne 0 ]; then
        echo -e "\n${RED}── Erreur ───────────────────────────────${NC}"
        head -n 5 "$output_file"
        echo -e "${RED}──────────────────────────────────────────${NC}"
        rm -f "$output_file"
        return 1  # Continue le script malgré l'erreur
    fi
    
    rm -f "$output_file"
    echo ""
}

# Vérification des arguments
url="$1"
if [ -z "$url" ]; then
    echo -e "${RED}Usage: $0 <domain>${NC}"
    exit 1
fi

echo -e "\n${BLUE}=== Reconnaissance Automatisée ===${NC}\n"

# 1. Initialisation des répertoires
run_task "Initialisation des répertoires" \
    "mkdir -p '$url'/recon/{scans,httprobe,potential_takeovers,wayback/{params,extensions}} && \
     touch '$url/recon/httprobe/alive.txt' '$url/recon/final.txt'"

# 2. Récolte de sous-domaines
run_task "Récolte de sous-domaines (assetfinder)" \
    "assetfinder '$url' | grep -E '${url//./\\.}' | tee '$url/recon/final.txt'"

# 3. Recherche de domaines vivants
run_task "Recherche de domaines vivants (httprobe)" \
    "cat '$url/recon/final.txt' | sort -u | httprobe -s -p https:443 | \
     sed 's|https\?://||;s|:443||' | tee '$url/recon/httprobe/alive.txt'"

# 4. Vérification des prises de contrôle
run_task "Vérification des prises de contrôle (subjack)" \
    "wget -q https://raw.githubusercontent.com/haccer/subjack/master/fingerprints.json -O - | \
     subjack -w '$url/recon/final.txt' -t 100 -timeout 30 -ssl -c /dev/stdin -v 3 -o '$url/recon/potential_takeovers/potential_takeovers.txt'"

# 5. Scan des ports ouverts
run_task "Scan des ports ouverts (nmap)" \
    "nmap -iL '$url/recon/httprobe/alive.txt' -T4 -oA '$url/recon/scans/scanned.txt'"

# 6. Récupération des données Wayback
run_task "Récupération des données Wayback" \
    "waybackurls < '$url/recon/final.txt' | tee '$url/recon/wayback/wayback_output.txt'"

# 7. Extraction des paramètres
run_task "Extraction des paramètres Wayback" \
    "grep '?[^=]*=' '$url/recon/wayback/wayback_output.txt' | cut -d '=' -f 1 | sort -u | tee '$url/recon/wayback/params/wayback_params.txt'"

# 8. Extraction des extensions
run_task "Extraction et compilation des fichiers js/php/aspx/jsp/json" \
    "echo '[+] Extraction des extensions...' && \
     rm -f '$url/recon/wayback/extensions/'*.txt && \
     for line in \$(cat '$url/recon/wayback/wayback_output.txt'); do \
         ext=\${line##*.}; \
         if [[ \"\$ext\" == \"js\" ]]; then \
             echo \$line >> '$url/recon/wayback/extensions/js1.txt'; \
             sort -u '$url/recon/wayback/extensions/js1.txt' >> '$url/recon/wayback/extensions/js.txt'; \
         fi; \
         if [[ \"\$ext\" == \"html\" ]]; then \
             echo \$line >> '$url/recon/wayback/extensions/jsp1.txt'; \
             sort -u '$url/recon/wayback/extensions/jsp1.txt' >> '$url/recon/wayback/extensions/jsp.txt'; \
         fi; \
         if [[ \"\$ext\" == \"json\" ]]; then \
             echo \$line >> '$url/recon/wayback/extensions/json1.txt'; \
             sort -u '$url/recon/wayback/extensions/json1.txt' >> '$url/recon/wayback/extensions/json.txt'; \
         fi; \
         if [[ \"\$ext\" == \"php\" ]]; then \
             echo \$line >> '$url/recon/wayback/extensions/php1.txt'; \
             sort -u '$url/recon/wayback/extensions/php1.txt' >> '$url/recon/wayback/extensions/php.txt'; \
         fi; \
         if [[ \"\$ext\" == \"aspx\" ]]; then \
             echo \$line >> '$url/recon/wayback/extensions/aspx1.txt'; \
             sort -u '$url/recon/wayback/extensions/aspx1.txt' >> '$url/recon/wayback/extensions/aspx.txt'; \
         fi; \
     done && \
     rm -f '$url/recon/wayback/extensions/js1.txt' && \
     rm -f '$url/recon/wayback/extensions/jsp1.txt' && \
     rm -f '$url/recon/wayback/extensions/json1.txt' && \
     rm -f '$url/recon/wayback/extensions/php1.txt' && \
     rm -f '$url/recon/wayback/extensions/aspx1.txt'"
# Résumé final
echo -e "${GREEN}=== Reconnaissance terminée avec succès! ==="
echo -e "╭──────────────────────────────────────────╮"
[ -s "$url/recon/final.txt" ] && \
    echo -e "│ ${CYAN}• Sous-domaines trouvés${GREEN} : $(wc -l < "$url/recon/final.txt")$(printf '%*s' 10 | tr ' ' ' ')│"
[ -s "$url/recon/httprobe/alive.txt" ] && \
    echo -e "│ ${CYAN}• Domaines actifs${GREEN} : $(wc -l < "$url/recon/httprobe/alive.txt")$(printf '%*s' 13 | tr ' ' ' ')│"
[ -s "$url/recon/wayback/wayback_output.txt" ] && \
    echo -e "│ ${CYAN}• URLs historiques${GREEN} : $(wc -l < "$url/recon/wayback/wayback_output.txt")$(printf '%*s' 9 | tr ' ' ' ')│"
echo -e "╰──────────────────────────────────────────╯"
echo -e "Résultats disponibles dans: ${CYAN}$url/recon/${NC}\n"