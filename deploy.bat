
echo ��ǰĿ¼��: %cd%
echo;

echo ��ʼ��ӱ����git add .
git add .
echo;

set /p declation=�����ύ��commit��Ϣ:
git commit -m "%declation%"
echo;

echo ���������ύ��Զ��
git push origin HEAD:main
echo;

pause