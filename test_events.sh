#!/bin/bash
# Test Event Generator Script for Linux/Mac
# Sends sample analytics events to test the platform

set -e

# Color codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}📤 Sending Test Analytics Events${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

API_URL="http://localhost:8000/api/events"
EVENT_COUNT=20

echo -e "${YELLOW}🎯 Sending $EVENT_COUNT sample events...${NC}"
echo ""

for i in $(seq 1 $EVENT_COUNT); do
    USER_ID="user_$((RANDOM % 10 + 1))"
    SESSION_ID="session_$((RANDOM % 5 + 1))"
    
    # Random page
    PAGES=("/" "/home" "/products" "/about" "/contact" "/blog")
    PAGE_PATH=${PAGES[$((RANDOM % ${#PAGES[@]}))]}
    
    # Random event type
    EVENT_TYPES=("page_visited" "page_visited" "button_clicked" "page_closed")
    EVENT_TYPE=${EVENT_TYPES[$((RANDOM % ${#EVENT_TYPES[@]}))]}
    
    # Build JSON payload
    if [ "$EVENT_TYPE" = "button_clicked" ]; then
        BUTTONS=("signup_btn" "login_btn" "cta_btn" "nav_btn")
        BUTTON_ID=${BUTTONS[$((RANDOM % ${#BUTTONS[@]}))]}
        JSON="{\"event_type\":\"$EVENT_TYPE\",\"user_id\":\"$USER_ID\",\"session_id\":\"$SESSION_ID\",\"page_path\":\"$PAGE_PATH\",\"button_id\":\"$BUTTON_ID\"}"
    else
        JSON="{\"event_type\":\"$EVENT_TYPE\",\"user_id\":\"$USER_ID\",\"session_id\":\"$SESSION_ID\",\"page_path\":\"$PAGE_PATH\"}"
    fi
    
    # Send event
    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "$JSON" \
        -w "\n%{http_code}")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ [$i/$EVENT_COUNT] Sent $EVENT_TYPE for $USER_ID on $PAGE_PATH${NC}"
    else
        echo -e "${RED}❌ [$i/$EVENT_COUNT] Failed to send event (HTTP $HTTP_CODE)${NC}"
    fi
    
    sleep 0.1
done

echo ""
echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}✅ Test events sent successfully!${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""
echo -e "${YELLOW}⏳ Wait 5-10 minutes for ETL to process events${NC}"
echo -e "${CYAN}📊 Then check dashboard at: http://localhost:3000${NC}"
echo ""

