
echo 当前目录是: %cd%
echo;

echo 开始添加变更：git add .
git add .
echo;

set /p declation=输入提交的commit信息:
git commit -m "%declation%"
echo;

echo 将变更情况提交到远程
git push origin HEAD:main
echo;

pause