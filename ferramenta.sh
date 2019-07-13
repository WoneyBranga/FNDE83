#/bin/sh
#set -xv # Habilita modo de depuração do script...
versao_atual=0.4 #variavel para utilização futura em ferramenta com atualização automatica...
###########################################################
# Programa de Diagnóstico para problemas comuns do FNDE83 #
###########################################################

#===============================================================================================================
#===============================================================================================================
#Programa pode ser Utilizado/Modificado/Distribuido desde que preserve dados do desenvolverdor abaixo informado!
#
# PROGRAMA DESENVOLVIDO POR WONEY BRANGA 
#
#    CONTATOS:
#            EMAIL: WONEY.BRANGA@GMAIL.COM
#            MSN: WONEY@KCH.COM.BR
#            CELULAR: (48) 98401-4022
#
#===============================================================================================================
#===============================================================================================================
#VARIÁVEIS A SEREM SETADAS
numero_pacotes_ping=2 #Quanto mais pacotes, mais lento... porem mais confiavel o teste... 3 é aceitavel...
ip_access_point=192.168.0.1
ip_sevidor=192.168.0.2
ip_impressora=192.168.0.3
diretorio=`pwd`
mac_eth0=`ifconfig eth0 | grep eth0 | tail -c 20 |tr -d " " | sed s/:/_/ | sed s/:/_/ | sed s/:/_/ | sed s/:/_/ | sed s/:/_/ | sed s/:/_/`

###########################################################
# Realiza Testes de PING contra Interfaces desejadas.
###########################################################
teste_ping()
{
  count=$(ping -c $numero_pacotes_ping $1 | grep 'received' | awk -F',' '{ print $2 }' | awk '{ print $1 }')
  if [ $count = $numero_pacotes_ping ]; then
    #falhou...
    echo "\033[42;30mSucesso contra $1\033[m"
tabela_html "Ping:>$1" "OK" "Sem_problemas_o_Ping:>$1"
vf_ping=1
  else 
    #sucesso...
    echo "\033[41;33;1mFalhou contra $1\033[m"
tabela_html "Ping:>$1" "FALHOU" "Problemas com o Ping:> $1,verificar!"
vf_ping=0
  fi
}
###########################################################
# Realiza Testes de reconhecimento dos hws
###########################################################
teste_hw()##
{
if [ -n `lspci |grep $1` ]; then
    #falhou...
    echo "\033[41;30;1m	Falha ao reconhecer: $1\033[m"
tabela_html "Reconhecendo hw $1" "FALHOU" "Problemas com a $1. Realizar seguintes testes:$2"
  else
    #sucesso...
    echo "\033[42;30m	Sucesso ao reconhecer: $1\033[m"
tabela_html "Reconhecendo hw $1" "OK" "LE reconheceu sem problemas a interface $1. (lspci) "
  fi
}
###########################################################
# Compara arquivos de configuração do sistema com arquivos "modelo"
###########################################################
compara_arquivos()
{
	if [ -n `diff $1 $2` ]; then
#OK
		echo "\033[42;30mARQUIVOS \"$1\" IGUAL ao \"$2\"\033[m"
		tabela_html "Checando:>\"$2\"" "OK" "Arquivo:>\"$2\" igual ao modelo."
	else
#NOK
		echo "\033[41;33;1mARQUIVO \"$2\" DIFERENTE DE \"$1\", Sugerido troca...\033[m"
		tabela_html "Checando:>\"$2\"" "FALHOU" "Arquivo:>\"$2\" Diferente do modelo."
		dialog --stdout --backtitle "Comparando arquivos..." --title "A T E N Ç Â O" --yesno "O arquivo comparado($2) é DIFERENTE do arquivo modelo($1), 

             corrigir agora?" 8 100
		if [ $? = 0 ]; then
			echo "\033[42;30mTroca autorizada pelo usuário, realizando troca...\033[m"
			corrige_arquivos $1 $2
		else
		echo "\033[41;33;1mTroca cancelada pelo usuário\033[m"
			dialog --stdout --backtitle "Comparando arquivos..." --msgbox "Arquivo NÃO FOI CORRIGIDO!!!" 5 35
		fi
	fi
}
###########################################################
# realiza a substituição de um determinado arquivo... informar Origem e Destino
###########################################################
corrige_arquivos()
{
#faz backup do arquivo atual.
	cp -b $2 $2.bkp_k
	echo "\033[42;30mcriado um backup do arquivo \"$2\" como \"$2.bkp_k\" \033[m"
	tabela_html "Criando bkp de arquivo "OK." Arquivo:>$2.bkp_k gerado com sucesso"
#Substitui arquivo...
	cp -b $1 $2
	echo "\033[42;30mSubstituido arquivo de configuração \"$2\" pelo arquivo modelo \"$1\"\033[m"
	tabela_html "Substituindo arquivo" "OK." "Arquivo:>$1 foi substituido por $2"
}
###########################################################
# Verifica ESSID ativo 
###########################################################
verifica_essid()##
{
	if [ -n `iwconfig $1 | grep $2` ]; then
#falhou...
		#  echo "ESSID atualmente associado a interface $1 não é $2!!!"
	tabela_html "Verificando ESSID" "FALHOU" "Placa NAO está configurada corretamente!!!<br>Se problema está em todas as máquinas, é bem provavel que o problema esteja no Access Point!<ul><li>1- Checar se Access Point está ligado e configurado corretamente!
<li>2- Resetar o Access Point no botão de Reset da parte traseira do AP.
<li>3- Verificar se não existe uma fonte de interferencia, caso exista, tentar mudar o canal do AP para resolver problema
<li>4- Tentar Verificar redes disponiveis com o comando <b>iwlist wlan0 scanning<b>"
		vf_essid=0
	else
#sucesso...
		#  echo "	Sucesso ao reconhecer Server"
	tabela_html "Verificando ESSID" "OK" "ESSID setado para Wireless é $2 "
		vf_essid=1
	fi
}
###########################################################
# Checa ip reconhecido pela interface 
###########################################################
verifica_ip()##
{
numero_ip=`ifconfig $1 | grep "inet end" | awk -F':' '{ print $2 }' | awk '{ print $1 }'`
numero_ip_192=`ifconfig $1 | grep "inet end" | awk -F':' '{ print $2 }' | awk '{ print $1 }' | grep "192.168"`
	if [ -z $numero_ip ]; then
#falhou...
		echo "\033[41;33;1mNão pegou IP na interface $1\033[m"
		#pede_ip $1
	tabela_html "Verificando IP" "FALHOU" "NAO reconheceu IP para $1"
vf_ip=0
	else
#sucesso...
		if [ -z $numero_ip_192 ]; then	
			echo "\033[41;33;1mReconheceu IP INVALIDO NA REDE... \"$numero_ip\" na interface $1\033[m"
			#pede_ip $1	
	tabela_html "Verificando IP" "FALHOU" "Pegou IP, mas não válido para a rede $1 (<b>$numero_ip</b>)"
		else
			echo "\033[42;30mReconheceu IP como: \"$numero_ip\" na interface $1\033[m"
	tabela_html "Verificando IP" "OK" "IP setado para $1 é <b>$numero_ip</b>"
vf_ip=1		
		fi
	fi
}
###########################################################
# Reinicia Serviços de rede...
###########################################################
reinicia_rede()
{
	echo "\033[42;30mReiniciando serviços de rede\033[m"
	tabela_html "Reiniciando rede" "OK." "Servicos de rede foram reiniciados..."
	/etc/init.d/networking restart |grep "* Reconfiguring"
}
###########################################################
# Pede IP ao servidor DHCP
###########################################################
pede_ip()
{
	echo "\033[42;30mPedindo IP ao Servidor DHCP\033[m"
	tabela_html "Solicitando IP" "OK." "Solicitando IP ao Servidor DHCP(Access_Point)"
	dhclient $1 |grep "No DHCPOFFERS"
}
###########################################################
# Resseta Gateway
###########################################################
reseta_gateway()
{
	echo "\033[42;30mRedefinindo Gateway padrão... Rota padrão será: $1\033[m"
	tabela_html "Apagando Rota" "OK" "Apagando rota default de rede..."
	route del default
	route add default $1 
	echo "Definindo Rota" "OK" "Definido como saida default para a rede interface: $1"
	tabela_html "Definindo Rota" "OK." "Definido como saida default para a rede interface: $1"
	echo "\033[42;30mMostrando tabela de rotas...\033[m"
	route
}
###########################################################
# Faz Diagnóstico completo na interface Wireless...
###########################################################
testes_wireless()
{
verifica_essid $1 "proinfo"
	if [ $vf_essid = 1 ]; then
		echo "\033[42;30messid OK\033[m"
	teste_ping $ip_access_point
		if [ $vf_ping = 1 ]; then
			echo "\033[42;30mPing Rodou com sucesso contra $ip_access_point\033[m"
		else
			echo "\033[41;33;1mNAO PINGOU... TENTANDO CORRIGIR...\033[m"
	## Verifica se conteúdo dos arquivos de configuração estão corretos...
	## Caso não, corrige arquivos com base nos arquivos modelo...
			compara_arquivos "$diretorio/config_rede_estacao/interfaces" "/etc/network/interfaces" "rede"
			compara_arquivos "$diretorio/config_rede_estacao/wpa_supplicant.conf" "/etc/wpa_supplicant.conf" "rede"
	## Apos corrigir arquivos, temos que reiniciar serviços para ativar novas configurações...segue...
			reinicia_rede 
			verifica_ip $1
			reseta_gateway $1
			teste_ping $ip_access_point
		fi
	###########################################################################
	teste_ping $ip_sevidor
		if [ $vf_ping = 1 ]; then
			echo "\033[42;30mPing Rodou com sucesso contra $ip_access_point\033[m"
		else
			echo "\033[41;33;1mNAO PINGOU... TENTANDO CORRIGIR...\033[m"
	## Verifica se conteúdo dos arquivos de configuração estão corretos...
	## Caso não, corrige arquivos com base nos arquivos modelo...
			compara_arquivos "$diretorio/config_rede_estacao/interfaces" "/etc/network/interfaces" "rede"
			compara_arquivos "$diretorio/config_rede_estacao/wpa_supplicant.conf" "/etc/wpa_supplicant.conf" "rede"
	## Apos corrigir arquivos, temos que reiniciar serviços para ativar novas configurações...segue...
			reinicia_rede 
			verifica_ip $1
			reseta_gateway $1
			teste_ping $ip_sevidor
		fi
	###########################################################################
	teste_ping $ip_impressora
		if [ $vf_ping = 1 ]; then
			echo "\033[42;30mPing Rodou com sucesso contra $ip_access_point\033[m"
		else
			echo "\033[41;33;1mNAO PINGOU... TENTANDO CORRIGIR...\033[m"
	## Verifica se conteúdo dos arquivos de configuração estão corretos...
	## Caso não, corrige arquivos com base nos arquivos modelo...
			compara_arquivos "$diretorio/config_rede_estacao/interfaces" "/etc/network/interfaces" "rede"
			compara_arquivos "$diretorio/config_rede_estacao/wpa_supplicant.conf" "/etc/wpa_supplicant.conf" "rede"
	## Apos corrigir arquivos, temos que reiniciar serviços para ativar novas configurações...segue...
			reinicia_rede 
			verifica_ip $1
			reseta_gateway $1
			teste_ping $ip_impressora
		fi
	else
			echo "\033[41;33;1mESSID ATUAL NÃO ESTÁ CORRETO, TENTANDO CORRIGIR...\033[m"
## Verifica se conteúdo dos arquivos de configuração estão corretos...
## Caso não, corrige arquivos com base nos arquivos modelo...
		compara_arquivos "$diretorio/config_rede_estacao/interfaces" "/etc/network/interfaces" "rede"
		compara_arquivos "$diretorio/config_rede_estacao/wpa_supplicant.conf" "/etc/wpa_supplicant.conf" "rede"
## Apos corrigir arquivos, temos que reiniciar serviços para ativar novas configurações...segue...
		reinicia_rede 
		verifica_ip $1
		reseta_gateway $1
	fi
verifica_ip $1
	if [ $vf_ip = 1 ]; then
		echo "\033[42;30mip OK ($numero_ip)\033[m"
	else
		echo "\033[41;33;1mip NOK\033[m"
	fi
}
###########################################################
# realiza ajuste para o funcionameto do relatório Unificado.
# REQUER "doc.rtf" na mesma pasta do Shell Script!!!
###########################################################
unifica_relatorios()
{
dialog --backtitle "Otimização relatórios de fechamento" --title 'ATENCAO' --stdout --yesno 'Deseja unificar os 02 relatórios de fechamentos em um único documento?' 0 0

if [ $? = 0 ]; then

	corrige_arquivos "$diretorio/doc_unificado/doc.rtf" "/usr/lib/formProinfo/bin/doc.rtf"

echo "Este script altera o relatório padrão do Termo de Aceitação fazendo com que sejam preenchidos 
os 02 relatórios de uma só vez!!!.

##########################################################
ATENTAR-SE PARA OS SEGUINTES PONTOS IMPORTANTES > > >
##########################################################

1- Alterar os campos ############ pelos seus devidos valores.
2- Ajustar os campos de observação relatando todos os problemas encontrados, principalmente:
>> Recoverys realizados;
>> Maquinas Abertas;
>> Peças faltantes ou com defeito;
>> Infras com problemas...
>> CARIMBAR OS 2 RELATÓRIOS!!!
Dúvidas, nos ligar!!!
0800-6436438 opção 9 INFRACD!" > /tmp/variante

dialog --backtitle "Informações importantes para o fechamento" --stdout --title "L E I A  C O M  A T E N Ç Ã O!!!" --textbox /tmp/variante 0 0
else
echo "Não foi corrigido a pedido do usuario"
fi
}
###########################################################
# Verifica Licença UserFul
###########################################################
verifica_userful()
{
echo "\033[44;30mTestando Licença USERFUL\033[m"
		if [ -z `find /etc/X11/ -name 1Box.info` ]; then
			echo "Checando Licença do USERFUL..." "\033[41;33;1m FALHOU...\033[m"
tabela_html "Verifica UserFul" "FALHOU" "Arquivo /etc/X11/1Box.info não foi encontrado!"
			# Módulo que tenta encontrar na pasta de licenças backupeadas uma licença válida para o UserFul
			encontra_bkp_registro_userful 
		else
			echo "Checando Licença do USERFUL..." "\033[42;30m OK...\033[m"
tabela_html "Verifica UserFul" "OK" "Arquivo /etc/X11/1Box.info encontrado com sucesso!"
			# Módulo que faz apenas para uma possível necessidade futura o backup do registro atual do UserFul
			bkp_registro_userful 
		fi
}
verifica_userful_pos_offline()
{
echo "\033[44;30mTestando Licença USERFUL\033[m"
		if [ -z `find /etc/X11/ -name 1Box.info` ]; then
			echo "Checando Licença do USERFUL..." "\033[41;33;1m FALHOU...\033[m"
tabela_html "Verifica Novo Procedimento de registro UserFul" "FALHOU" "Mesmo após novo procedimento de registro maquina não validou registro Userful, realziar seguintes passos:<ul>
<li>1- Ligar para positivo no 41 3316-7800 e informar que procedimento não funcionou e anotar o nome do atendente e informar este no fechamento do chamado!
<li>2- Fechar chamado na intranet como SOLICITAR MATERIAL e informar na descrição Numero de série do equipamento, MacAddress da placa Eth0 e atendente da positivo.
<li>Exemplo de fechamento: 
<br><i><b>Equipamento não validou registro do userful mesmo com novo procedimento. Conversado com zezinho do suporte e este informou que devemos aguarda novo registro. numero de serie 10203040 Mac Address 00:11:22:33:44:55</b></i>"

		else
			echo "Checando Licença do USERFUL..." "\033[42;30m OK...\033[m"
tabela_html "Verifica Novo Procedimento de registro UserFul" "OK" "REGISTROU COM NOVO PROCEDIMENTO(03/08/2010) Arquivo /etc/X11/1Box.info encontrado com sucesso!"
			 
		fi
}
bkp_registro_userful()
{
sudo cp -v /etc/X11/1Box.info "$diretorio/Bkp_Userful/1Box.info($mac_eth0)" 
	tabela_html "Realizando bkp Licença USerful" "OK." "Realizado Backup da licença do sistema Userful!!!"
}
###########################################################
# Encontra/Restaura Registro do Userful, se backupeado...
###########################################################
userful_novo_teste()
{
#	if [ -z `cat /etc/userful/userful-license-info | grep "EXPIRY_DATE=0"` ]; then
	if [ `cat /etc/userful/userful-license-info | grep "EXPIRY_DATE=0"` = "EXPIRY_DATE=0" ]; then
#falha

	tabela_html "XXXRegistro Nao realzado" "FALHA" "Nao realizada tentativa de registro por decisao do usuario"
	echo "NAO REGISTRADO"

	else
#ok
	tabela_html "XXXRegistro realzado" "OK" "Nao realizada tentativa de registro por decisao do usuario"
	echo "REGISTRADO!!!!"
	fi
}
encontra_bkp_registro_userful()
{
	if [ -z `find "$diretorio/Bkp_Userful/" -name "1Box.info($mac_eth0)"` ]; then
#FALHA
		echo "Não foi encontrado o Arquivo de Backup do Userful"
	tabela_html "Verificando bkp USerful" "FALHOU" "Não foi encontrado o Backup do Userful, realizar procedimentos do manual para Registro do UserFul!!!"

###@@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ 
###@@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ 
		dialog --stdout --backtitle "Registro UserFul" --title "A T E N Ç Â O" --yesno "Não foi possivel encontrar o Registro do UserFul e backup desta licença.

             Deseja executar NOVO procedimento(03/08/2010) de registro Off-Line do Userful???" 8 100
		if [ $? = 0 ]; then
			echo "\033[42;30mExecutando tentativa de registro Off-Line...\033[m"
			implanta_licencas_off_line
		else
		echo "\033[41;33;1mTentativa de registro Off-Line NAO AUTORIZADA PELO USUARIO...\033[m"
			dialog --stdout --backtitle "Comparando arquivos..." --msgbox "Arquivo NÃO FOI CORRIGIDO!!!" 5 35
	tabela_html "Registro Nao realzado" "FALHA" "Nao realizada tentativa de registro por decisão do usuário"

		fi

###@@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ 
###@@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ @@@ 

	else
#OK
		echo "Encontrado arquivo backup, realizando restauração..."
	tabela_html "Verificando bkp USerful" "OK" "Backup encontrado!!!"
		rm /etc/X11/1Box.info.trial
	tabela_html "Apagando registro Trial" "OK." "Apagada licença Trial do UserFul para a inclusão da definitiva"
		corrige_arquivos "$diretorio/Bkp_Userful/1Box.info($mac_eth0)" "/etc/X11/1Box.info"

	tabela_html "Registrando Userful" "OK." "Registro REALIZADO com base no Backup realizado anteriormente!!!<br> $diretorio/Bkp_Userful/1Box.info($mac_eth0)"
	fi
}
implanta_licencas_off_line()
{
tabela_html "Realizando Registo USerful off-line" "OK." "Realizado procedimento(03/08/2010) de registro OFF-LINE licença do sistema Userful!!!"
tar zxvf X11.tar.gz -C /etc/
verifica_userful_pos_offline
}





###########################################################
# Verifica conteudo MEC
###########################################################
verifica_conteudo_mec()
{
echo "\033[44;30mTestando Conteudo MEC\033[m""Comando utilizado => \033[40;33;1mdu -s /home/ConteudoMEC/ \033[m"
mec=`du -s /home/ConteudoMEC/ | cut -f 1`
if [ $mec -gt 22681300 ]; then
	echo "Checando conteudo da pasta ConteudoMEC..." "\033[42;30m OK...\033[m"
	tabela_html "Verifica Conteudo MEC" "OK" "Conteudo aparentemente reconhecido..."
else
	echo "Checando conteudo da pasta ConteudoMEC..." "\033[41;33;1m FALHOU...\033[m"
	tabela_html "Verifica Conteudo MEC" "FALHOU" "Não foi encontrado o ConteudoMEC, CONFIRMAR!!!"
fi
}
###########################################################
# Pede IP ao servidor DHCP
###########################################################
roda_video()
{
	echo "\033[41;33;1mCarrega Vídeo para teste do SOM

VERIFICAR se fone de ouvido está funcionando corretamente
VERIFICAR se fone de ouvido está funcionando corretamente
VERIFICAR se fone de ouvido está funcionando corretamente

Fechar vídeo para continuação dos testes
Fechar vídeo para continuação dos testes
Fechar vídeo para continuação dos testes
Fechar vídeo para continuação dos testes\033[m"

	echo "Carregando video" "OK" "Carrega Vídeo para teste do SOM"
sudo -u professor vlc /home/ConteudoMEC/tvescola/dvdii/05\ Educação\ Física/Esporte\ Na\ Escola/04\ Cidadania\ em\ construção\ .WMV
}
###########################################################
# Monta Relatório HTML com resultados dos testes. salva e, /tmp/testes.htm
###########################################################
monta_html()
{
printf '
<html><head>
<meta http-equiv="content-type" content="text/html;charset=UTF-8" />
<title>Sistema de Diagnóstico de Falhas - FNDE83/2009 V0.4b"</title>
</head>
<body >
<font size="5" face="Times">Sistema de Diagnóstico de Falhas - FNDE83/2009 V0.4b</font>
<br>'> $diretorio/resultado_testes.htm

echo "<hr>Tipo de equipamento: `hostname`<br>
Número de Série: `dmidecode | head -n 47 | tail -n 1 | cut -f 2 -d ":"`<br>
Endereço MAC da eth0: `ifconfig eth0 | grep eth0 | tail -c 20 |tr -d " "`<br>
Data e Hora: `date +%d/%m/%Y" "%H:%m:%S`<hr>" >> $diretorio/resultado_testes.htm
printf '
<font size="2" face="Times" align="center">
<table border="0" cellspacing="2" cellpadding="2" >
<tr>
	<td bgcolor=#E1E1E1 align=center><b>Teste</td>
	<td bgcolor=#E1E1E1 align=center><b>Resultado</td>
	<td bgcolor=#E1E1E1 align=center><b>Detalhes</td>
</tr>' >> $diretorio/resultado_testes.htm
}
tabela_html()
{
if [ $2 = "OK" ]; then
printf "
<tr>
	<td bgcolor=#D7FFD7 align=center>$1</td>
	<td bgcolor=#D7FFD7 align=center>$2</td>
	<td bgcolor=#D7FFD7>$3</td>
</tr>" >> $diretorio/resultado_testes.htm
fi
	if [ $2 = "OK." ]; then
	printf "
	<tr>
		<td bgcolor=#DFEFFF align=center>$1</td>
		<td bgcolor=#DFEFFF align=center>$2</td>
		<td bgcolor=#DFEFFF>$3</td>
	</tr>" >> $diretorio/resultado_testes.htm
	fi
	if [ $2 = "FALHA" ]; then
	printf "
	<tr>
		<td bgcolor=#DFEFFF align=center>$1</td>
		<td bgcolor=#DFEFFF align=center>$2</td>
		<td bgcolor=#DFEFFF>$3</td>
	</tr>" >> $diretorio/resultado_testes.htm
	fi
corrige_arquivos()
{
#faz backup do arquivo atual.
	cp -b $2 $2.bkp_k
	echo "\033[42;30mcriado um backup do arquivo \"$2\" como \"$2.bkp_k\" \033[m"
	tabela_html "Criando bkp de arquivo "OK." Arquivo:>$2.bkp_k gerado com sucesso"
#Substitui arquivo...
	cp -b $1 $2
	echo "\033[42;30mSubstituido arquivo de configuração \"$2\" pelo arquivo modelo \"$1\"\033[m"
	tabela_html "Substituindo arquivo" "OK." "Arquivo:>$1 foi substituido por $2"
}
		if [ $2 = "FALHOU" ]; then
		printf "
		<tr>
			<td bgcolor=#FFD2D2 align=center>$1</td>
			<td bgcolor=#FFD2D2 align=center>$2</td>
			<td bgcolor=#FFD2D2 font=arial>$3</td>
		</tr>" >> $diretorio/resultado_testes.htm
		fi
		}
mostra_html()
{
printf '</table></font></body></html>' >> $diretorio/resultado_testes.htm
firefox $diretorio/resultado_testes.htm
}
###########################################################
# Script ATUALIZA_MEC fornecido pela POSITIVO para a correção de alguns problemas...
###########################################################
atualiza_mec()
{
# Altera as permissões do diretorio com os conteudos educacionais - resolve problema de acesso da EduBar
echo "Alterando ConteudoMEC"
chmod 755 -R /home/ConteudoMEC/
chown root.root -R /home/ConteudoMEC/

# Altera as permissões do script da EduBar para corrigir bug de permissao na abertura dos arquivos de vídeo
echo "Alterando Script EduBar"
chmod 755 /usr/bin/EduBar
chown root.root /usr/bin/EduBar

# Copia a nova versao do agente (IdAgent) que envia a informação do MAC e NR. SERIE das estacoes para o servidor
echo "Alterando agente formulario IdAgent"
cp $diretorio/atualiza_mec/IdAgent /usr/bin/
chown root.root /usr/bin/IdAgent
chmod 755 /usr/bin/IdAgent

# Correção da associação de arquivos (tipo mime) (
echo "Alterando associaçao tipo MIME"
TIPO=`hostname`
if [ $TIPO = "servidor" ]
then
   echo "Alterando servidor"
   rm -rf /home/professor/.kde/share/mimelnk/application/x-ms-wmv.desktop
   rm -rf /home/professor/.kde/share/mimelnk/audio/x-ms-wmv.desktop
   cp -rf $diretorio/atualiza_mec/x-mplayer2.desktop /home/professor/.kde/share/mimelnk/application/
   cp -rf $diretorio/atualiza_mec/x-ms-wmv.desktop /home/professor/.kde/share/mimelnk/video/

   rm -rf /home/aluno/.kde/share/mimelnk/application/x-ms-wmv.desktop
   rm -rf /home/aluno/.kde/share/mimelnk/audio/x-ms-wmv.desktop
   cp -rf $diretorio/atualiza_mec/x-mplayer2.desktop /home/aluno/.kde/share/mimelnk/application/
   cp -rf $diretorio/atualiza_mec/x-ms-wmv.desktop /home/aluno/.kde/share/mimelnk/video/

else
   echo "Alterando Estacao"
   rm -rf /home/professor/.kde/share/mimelnk/application/x-ms-wmv.desktop
   rm -rf /home/professor/.kde/share/mimelnk/audio/x-ms-wmv.desktop
   rm -rf /home/aluno1/.kde/share/mimelnk/application/x-ms-wmv.desktop
   rm -rf /home/aluno1/.kde/share/mimelnk/audio/x-ms-wmv.desktop
   rm -rf /home/aluno2/.kde/share/mimelnk/application/x-ms-wmv.desktop
   rm -rf /home/aluno2/.kde/share/mimelnk/audio/x-ms-wmv.desktop
   rm -rf /home/aluno3/.kde/share/mimelnk/application/x-ms-wmv.desktop
   rm -rf /home/aluno3/.kde/share/mimelnk/audio/x-ms-wmv.desktop

   cp $diretorio/atualiza_mec/x-mplayer2.desktop /home/professor/.kde/share/mimelnk/application/
   cp $diretorio/atualiza_mec/x-ms-wmv.desktop /home/professor/.kde/share/mimelnk/video/

   cp $diretorio/atualiza_mec/x-mplayer2.desktop /home/aluno1/.kde/share/mimelnk/application/
   cp $diretorio/atualiza_mec/x-ms-wmv.desktop /home/aluno1/.kde/share/mimelnk/video/

   cp $diretorio/atualiza_mec/x-mplayer2.desktop /home/aluno2/.kde/share/mimelnk/application/
   cp $diretorio/atualiza_mec/x-ms-wmv.desktop /home/aluno2/.kde/share/mimelnk/video/

   cp $diretorio/atualiza_mec/x-mplayer2.desktop /home/aluno3/.kde/share/mimelnk/application/
   cp $diretorio/atualiza_mec/x-ms-wmv.desktop /home/aluno3/.kde/share/mimelnk/video/
fi

rm -rf /etc/skel/.kde/share/mimelnk/application/x-ms-wmv.desktop
rm -rf /etc/skel/.kde/share/mimelnk/audio/x-ms-wmv.desktop
cp $diretorio/atualiza_mec/x-mplayer2.desktop /etc/skel/.kde/share/mimelnk/application/
cp $diretorio/atualiza_mec/x-ms-wmv.desktop /etc/skel/.kde/share/mimelnk/video/

# Correção de bug do KDM para resolver problema de reinicializacao do arquivo xorg.conf
echo "Corrigindo BUG Debconf" 
cp $diretorio/atualiza_mec/config.dat /var/cache/debconf/

# Correção associacao novo usuario a grupos no kuser
cp $diretorio/atualiza_mec/adduser.conf /etc/

tabela_html "CD Atualiza MEC" "OK." "Instalado todo conteúdo do CD Atualiza MEC..."
}
###########################################################
# Gera página teste para maquinas...
###########################################################

###########################################################
# Realiza Backup do registro Userful para PC atual
###########################################################
verifica_monitores()
{
	if [ -z `sudo cat /etc/X11/userful.Mxorg.conf | grep 1360x768` ]; then
#FALHA
		echo "Resolução incorreta encontrada!"
	tabela_html "Verificando Resolução utilizada" "FALHOU" "Resolução atualmente utilizada está incorreta, realizando correção..."
	else
#OK
		echo "Resolução correta encontrada"
	tabela_html "Verificando Resolução utilizada" "OK" "Resolução atualmente utilizada nos monitores está correta!"
	fi
}
creditos()
{
clear
dialog --stdout --backtitle "Créditos do Sistema" --title "CRÉDITOS..." --infobox "
SISTEMA DE DIAGNÓSTICO DE DISPOSITIVOS - FNDE 83/2009 V0.4

=================================================
DESENVOLVIDO PELA KOERICH TELECOM - >> INFRACD <<
=================================================

                Dúvidas: woney.branga@gmail.com (48) 98401-4022" 0 0
sleep 5
}

###########################################################
###########################################################
# Chama função para testes do SERVIDOR
###########################################################
###########################################################

###########################################################
###########################################################
# Chama função para testes das ESTAÇÕES
###########################################################
###########################################################
testa_estacao()
{
monta_html
teste_hw 'VGA' "<ul><li>se pifar, problema na placa mãe ou no sistema Operacional<li>se pifar, problema na placa mãe ou no sistema Operacional"
teste_hw 'Display' "<ul><li>1- Provavel mal contato da placa, abrir gabinete e reinserir placa.
<li>2- Encaixar placa em outro Slot para teste (slot placa Wireless)
<li>3- Testar placa em outro PC.
<li>4- Efetuar RECOVERY
<li>5- Caso problema persista, problema fisico, solicitar a troca da placa de video off-board(2 saidas)"
teste_hw 'Audio' "<ul><li>se pifar, problema na placa mãe ou no sistema Operacional<li>se pifar, problema na placa mãe ou no sistema Operacional"
teste_hw 'Ethernet' "<ul><li>se pifar, problema na placa mãe ou no sistema Operacional<li>se pifar, problema na placa mãe ou no sistema Operacional"
teste_hw "Network" "<ul><li>1- Reiniciar  computador
<li>2- Placa de rede wireless com provavel mal contato, abrir gabinete e reinserir placa.
<li>3- Encaixar placa em outro Slot para teste (slot placa Video)
<li>4- Testar placa em outro PC.
<li>5- Efetuar RECOVERY.
<li>6- caso persista, solicitar troca da placa wireless"	
verifica_monitores
#testes_wireless "wlan0"
verifica_essid
verifica_ip
#teste_ping $ip_access_point
#teste_ping $ip_sevidor
#teste_ping $ip_impressora
atualiza_mec
verifica_conteudo_mec
verifica_userful
userful_novo_teste
#roda_video Deve ser evoluida esta função!


mostra_html
#creditos

}

#set +xv




testa_estacao