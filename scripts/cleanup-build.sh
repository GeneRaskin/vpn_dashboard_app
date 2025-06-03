echo "🧹 Running a cleanup build script"

if [[ -f "backend/get_user_config/function.zip" ]]; then
    echo "🧹 Removing function.zip"
    rm -f "backend/get_user_config/function.zip"
fi

if [[ -f "backend/get_user_config/index.js" ]]; then
    echo "🧹 Removing generated index.js"
    rm -f "backend/get_user_config/index.js"
fi

if [[ -d "backend/get_user_config/node_modules" ]]; then
    echo "🧹 Removing generated node_modules"
    rm -rf "backend/get_user_config/node_modules"
fi

if [[ -f "backend/get_user_config/origin.txt" ]]; then
    echo "🧹 Removing generated origin.txt"
    rm -f "backend/get_user_config/origin.txt"
fi
