#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
/*---------+----------+-------+-----------------------+------+------------+
|Função    |TXMLSAI   | Autor |KENNY ROGER MARTINS    | Data | 03.10.2011 |
+----------+----------+-------+-----------------------+------+------------+       
|Descrição |TELA DE IMPORTAÇÃO DE NFe PARA O TMS                          |
+----------+--------------------------------------------------------------+
|Retorno   |NENHUM                                                        |
+----------+--------------------------------------------------------------+
|Parâmetros|NENHUM	   	      											  |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+--------------------------------------------------------------+
| Atualizacoes sofridas desde a Construcao Inicial.                       |
+-----------+----------+--------------------------------------------------+
| Subrotina |   Data   | Descrição                                        |
+-----------+----------+--------------------------------------------------+
| 		     |          |    				 					               |
+-----------+----------+-------------------------------------------------*/
USER FUNCTION TXMLSAI()                           
LOCAL nOPCA    := 0
LOCAL aSAYS    := {}
LOCAL aBUTTONS := {}
PRIVATE cCADASTRO := "Importa arquivo XML"

PROCLOGINI( aBUTTONS ) // Inicializa o log de processamento

AADD(aBUTTONS, { 1,.T.,{|o| nOPCA := 1, O:oWND:END()}} )
AADD(aBUTTONS, { 2,.T.,{|o| O:oWND:END() }} )

AADD (aSAYS, OemToAnsi("Este programa tem como objetivo importar arquivos de XML e gerar  "))
AADD (aSAYS, OemToAnsi("nota fiscal EDI no módulo TMS.                                    "))

FORMBATCH( cCADASTRO, aSAYS, aBUTTONS,,,420)

IF nOPCA == 1
	ProcLogAtu("INICIO") 		  // Atualiza o log de processamento
	Processa({|lEnd| fEXECUTE()}) // Chamada da funcao
	ProcLogAtu("FIM") 			  // Atualiza o log de processamento
ENDIF

RETURN NIL
/*
LOCAL bPROCESS := {|oSELF| fEXECUTE(oSELF) }
LOCAL oPROCESS
LOCAL cPERG	   := ""
LOCAL cTITREL  := "Importação de XML para TMS"
LOCAL cDESROT  := ""

cDESROT := "Este programa tem como objetivo importar arquivos de XML e gerar "
cDESROT += "nota fiscal EDI no módulo TMS. "

oPROCESS := tNEWPROCESS():NEW("TXMLSAI", cTITREL, bPROCESS, cDESROT, cPERG,, .T., 5,, .T.)

RETURN                                                                                     
*/

/*---------+----------+-------+-----------------------+------+------------+
|Função    |IMPXML    | Autor |KENNY ROGER MARTINS    | Data | 03.10.2011 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |IMPORTA ARQUIVO XML                                           |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION fEXECUTE() //oPROCESS)
LOCAL aARQ
LOCAL nI		:= 0
LOCAL cFILE     := ""
LOCAL nTOTERRO  := 0
LOCAL nTOTREG   := 0

PRIVATE nERROR  := 0
PRIVATE cLOG	:= ""
PRIVATE cRAIZ	:= GETNEWPAR("ZZ_XMLTMS","\xml_tms\")                   

/*              
oPROCESS:SAVELOG("Início do processamento.")
oPROCESS:SAVELOG("Importação de XML.")
oPROCESS:SAVELOG("Usuário:      "+SUBSTR(cUSUARIO,7,15))
oPROCESS:SAVELOG("Filial:       "+cFILANT)
*/
/*------------------------------------------------------------------------+
|PERCORRE ARQUIVOS PARA IMPORTAR OS DADOS                                 |
+------------------------------------------------------------------------*/
//oPROCESS:SETREGUA1(1)
//oPROCESS:INCREGUA1("Abrindo arquivos da pasta...")
//oPROCESS:INCREGUA1("Arquivos XML carregados...")
//oPROCESS:SETREGUA2(LEN(aARQ))
//oPROCESS:INCREGUA2("Iniciando leitura dos arquivos...")

aARQ := DIRECTORY(cRAIZ+"*.xml")              
IF LEN(aARQ) <= 0
	cLog := cLog + Replicate("-", 60)+chr(13)+chr(10)
	cLog := cLog + "Atenção!!!" +chr(13)+chr(10)
	cLog := cLog + "Nenhum arquivo foi encontrado." +chr(13)+chr(10)
	cLog := cLog + Replicate("-", 60)+chr(13)+chr(10)
ENDIF

PROCREGUA(LEN(aARQ))
FOR nI := 1 TO LEN(aARQ)
	nERROR	:= 0
	cFILE	:= aARQ[nI,1]
	XMLNFE(cFILE)
	nTOTERRO := nTOTERRO + nERROR
	nTOTREG++     
	INCPROC("Registro: "+cVALTOCHAR(nTOTREG)+"/"+cVALTOCHAR(LEN(aARQ)))
//	oPROCESS:INCREGUA2("Registro: "+cVALTOCHAR(nTOTREG)+"/"+cVALTOCHAR(LEN(aARQ)))
NEXT
//oPROCESS:SAVELOG(cLOG)
//oPROCESS:SAVELOG("Total de registros processados: "+CVALTOCHAR(nTOTREG))
AUTOGRLOG(cLOG)
MOSTRAERRO()
//oPROCESS:SAVELOG("Término do processamento.")
RETURN NIL

/*---------+----------+-------+-----------------------+------+------------+
|Função    |XMLNFE    | Autor |                       | Data |            |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |IMPORTAÇÃO DO XML                                             |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+--------------------------------------------------------------+
|Observação|GERA NOTA FISCAL EDI                                          |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION XMLNFE(cFILE)         
LOCAL cERROR        := ""
LOCAL cWARNING		:= ""             
PRIVATE oXML		:= NIL
PRIVATE cNUM		//NUMERO DA NOTA
PRIVATE lOKITEM
PRIVATE nERRORITEM	:= 0
PRIVATE cCNPJEMIT
PRIVATE cCNPJDEST
PRIVATE cDtEmissao
PRIVATE nDescVar     := 0
PRIVATE nDescNota    := 0
PRIVATE nDescItens   := 0
PRIVATE cDescItem
PRIVATE nIcms        := 0
PRIVATE nIcmsRet     := 0
PRIVATE nIcmsRepa    := 0
PRIVATE nIcmsSubs    := 0
PRIVATE nSeguro      := 0
PRIVATE nFrete       := 0
PRIVATE nAdicional	 := 0
PRIVATE nIcmsPer
PRIVATE nIcmsBase
PRIVATE cSerie       := "1 "
PRIVATE cSerNFC      := "1 "
PRIVATE cTipo        := "N"
PRIVATE cICMS
PRIVATE cBaseICMS
PRIVATE cCFOP
PRIVATE cCod
PRIVATE nCont        := 0
PRIVATE cCodigo      := ""
PRIVATE cUM
PRIVATE bLote
Private cValidade
Private cCodBarra
Private nQuant       := 0
Private nPrcUnLiq    := 0
Private nDescItem    := 0// %
Private nValDesc     := 0// $
Private nItem        := 0
Private bMed
Private nContLote    := 0// Contador do For
Private nTotalMed    := 0// Len do Array Med
Private nQtdeLote    := 0 // Qtde do Lote Atual
Private nDescLote    := 0// Desconto do Lote Atual
Private nValLote     := 0// Valor do Lote Atual
Private nDescTT      := 0// Acumulado do Desconto
Private nValorTT     := 0// Acumulado
Private cUnidad   // Unidade do fornecedor
Private nFator       := 0// Fator de Conversao
Private nNumItens    := 0
Private nNumUnid     := 0
Private nTotalMerc   := 0
Private cNumTitulo
Private nValor       := 0
Private cVencimento
Private nDescDia     := 0
Private nDescFin     := 0
Private nJurosDia    := 0
Private nMulta       := 0
Private nAcrescimo   := 0
Private aCabec       := {}
Private aItens       := {}                                       
Private aLinha       := {}
Private lOk          := .T.
Private lMsErroAuto  := .F.
Private lMsHelpAuto  := .T.
Private cArqLog      := cRAIZ+substr(cFile,1,at(".xml",cFile)-1) /*+"_"+ dtos(date())*/+".log"
Private cFound       := 0 // Resultado de Busca
Private cCODCLI      := ""
Private cLOJCLI      := ""
Private cEmbal       := ""
Private cEmpresa                       
PRIVATE cCODEMB      := ""      
PRIVATE nBASEICMS    := 0
PRIVATE nVALORICMS   := 0
PRIVATE nBASEIST     := 0
PRIVATE nVALORIST    := 0

cEMPRESA := cEMPANT

oXML := XMLPARSERFILE(cRAIZ+cFILE, "_", @cError, @cWarning)     

cChave    := IF(TYPE("oxml:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT")  <> "U", oxml:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:TEXT, "")    
                  
oXML := IF(TYPE("oxml:_NfeProc")<>"U", oxml:_NFeProc:_NFe, oxml)

If Type("oXml") != "O"
	MsgAlert(cFile+" - "+cError)
	Return()
Endif

if Type("oxml:_InfNfe:_DET") == "O"
	XmlNode2Arr(oxml:_InfNfe:_DET, "_DET")
EndIf

cLog := cLog + Replicate("-", 60)+chr(13)+chr(10)
If Type("oXml") != "O"
	MsgAlert(cFile+" - "+cError)
	Return()
Endif

if Type("oxml:_InfNfe:_DET") == "O"
	XmlNode2Arr(oxml:_InfNfe:_DET, "_DET")
EndIf

cNum      := IF(TYPE("oxml:_INFNFE:_IDE:_NNF:TEXT")    <> "U", PADL(Alltrim(oxml:_INFNFE:_IDE:_NNF:TEXT),6,"0"), "") //Nro da Nota
cTpNF     := IF(TYPE("oxml:_INFNFE:_IDE:_TPNF:TEXT")   <> "U", oxml:_INFNFE:_IDE:_TPNF:TEXT, "")
cModelo   := IF(TYPE("oxml:_INFNFE:_IDE:_MOD:TEXT")    <> "U", oxml:_INFNFE:_IDE:_MOD:TEXT, "")
cSerie    := IF(TYPE("oxml:_InfNfe:_IDE:_Serie:Text")  <> "U", PADR(oxml:_InfNfe:_IDE:_Serie:Text,3," "), "")
cSerNFC   := IF(TYPE("oxml:_InfNfe:_IDE:_Serie:Text")  <> "U", PADR(oxml:_InfNfe:_IDE:_Serie:Text,3," "), "")

cIE_Emit  := IF(TYPE("oxml:_INFNFE:_EMIT:_IE:TEXT")    <> "U", oxml:_INFNFE:_EMIT:_IE:TEXT, "")
cNomeEmit := IF(TYPE("oxml:_INFNFE:_EMIT:_XNOME:TEXT") <> "U", oxml:_INFNFE:_EMIT:_XNOME:TEXT, "")
cCNPJEMIT := IF(TYPE("oxml:_INFNFE:_EMIT:_CNPJ:TEXT")  <> "U", oxml:_INFNFE:_EMIT:_CNPJ:TEXT, "")

cIE_Dest  := IF(TYPE("oxml:_INFNFE:_DEST:_IE:TEXT")    <> "U", oxml:_INFNFE:_DEST:_IE:TEXT, "")
cNomeDest := IF(TYPE("oxml:_INFNFE:_DEST:_XNOME:TEXT") <> "U", oxml:_INFNFE:_DEST:_XNOME:TEXT, "")
cCNPJDEST := IF(TYPE("oxml:_INFNFE:_DEST:_CNPJ:TEXT")  <> "U", oxml:_INFNFE:_DEST:_CNPJ:TEXT, "")

CADEDI(cFILE)

RETURN


/*---------+----------+-------+-----------------------+------+------------+
|Função    |CADEDI    | Autor | KENNY ROGER           | Data | 30/01/2015 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |                                                              |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION CADEDI(cFILE)
LOCAL nI                                     
LOCAL lPRODUTO := .T.                  
       
cLOG += "Documento de entrada: "+cNum+CHR(13)+CHR(10)

SA1->(DBSETORDER(3))

IF TYPE("oxml:_INFNFE:_TRANSP:_MODFRETE:TEXT")<>"U"
	IF ALLTRIM(oxml:_INFNFE:_TRANSP:_MODFRETE:TEXT)=="0"
		IF !(SA1->(DBSEEK(xFILIAL("SA1")+cCNPJEMIT)))
			CADEMIT()
		ENDIF
		SA1->(DBSEEK(xFILIAL("SA1")+cCNPJEMIT))
		cCODCLI  := SA1->A1_COD
		cLOJCLI  := SA1->A1_LOJA
	ELSE
		IF !(SA1->(DBSEEK(xFILIAL("SA1")+cCNPJDEST)))
			CADDEST()
		ENDIF
		SA1->(DBSEEK(xFILIAL("SA1")+cCNPJDEST))
		cCODCLI  := SA1->A1_COD
		cLOJCLI  := SA1->A1_LOJA
	ENDIF
ENDIF

IF DOCENTCAD()
	nError += 1
	cFound += 1
	
	cLog := cLog+"Nota fiscal do cliente já está cadastrado no sistema. O arquivo será removido para a pasta "+'"Duplicados"'+"."+CHR(13)+CHR(10)
	MoverArq(cRAIZ, "Duplicados", cFile, cFile)
	//U_Geralog("F"+cFilOrig+ " " +cNum+"-> Nao importada. Nota ja foi cadastrada. " + cFornec+"/"+cLjFornec,cArqlog)
ELSE                                
	nNumItens       := IF(TYPE("oxml:_InfNfe:_DET")<>"U", LEN(oxml:_InfNfe:_DET), 0)
	cDtEmissao      := IF(TYPE("oxml:_INFNFE:_IDE:_dEmi:Text")<>"U", oxml:_INFNFE:_IDE:_dEmi:Text, "")
	cDtEmissao      := IF(TYPE("oxml:_INFNFE:_IDE:_dHEmi:Text")<>"U", oxml:_INFNFE:_IDE:_dHEmi:Text, cDtEmissao)	
	cDtEmissao      := Substr(cDtEmissao,9,2)+"/"+Substr(cDtEmissao,6,2)+"/"+Substr(cDtEmissao,1,4)
	nTotalMerc      := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VPROD:Text)")<>"U", Val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VPROD:Text), 0) // Valor Mercadorias
	nDescNota       := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VDESC:Text")<>"U", val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VDESC:Text), 0)
	cNumTitulo      := cNum // Substr(cBuffer,1,10)
	nValor          := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VNF:Text")<>"U", Val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VNF:Text), 0)
	nBASEICMS       := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VBC:Text")<>"U", Val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VBC:Text), 0) // Valor Mercadorias
	nVALORICMS      := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VICMS:Text")<>"U", Val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VICMS:Text), 0) // Valor Mercadorias
	nBASEIST        := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VBCST:Text")<>"U", Val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VBCST:Text), 0) // Valor Mercadorias
	nVALORIST       := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VST:Text")<>"U", Val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VST:Text), 0) // Valor Mercadorias
	
	IF TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT") <> "U"
		If XmlChildEx ( oxml:_INFNFE:_TOTAL:_ICMSTOT , "VOUTRO" ) != Nil
			nAcrescimo  := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VOUTRO:Text")<>"U", Val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VOUTRO:Text), 0)
		Else
			nAcrescimo  := 0
		Endif
	ELSE
		nAcrescimo  := 0
	ENDIF
	
	cVencimento := ""
	
	IF TYPE("oxml:_INFNFE") <> "U"
		If XmlChildEx ( oxml:_INFNFE , "_COBR" ) != Nil
			// Voltar mas tem que alterar para aceitar varias parcelas.
			cVencimento := IF(TYPE("oxml:_INFNFE:_COBR:_DUP:_DVENC:Text")<>"U", oxml:_INFNFE:_COBR:_DUP:_DVENC:Text, "")
			cVencimento := Substr(cVencimento,9,2)+"/"+Substr(cVencimento,6,2)+"/"+Substr(cVencimento,1,4)
		EndIf
	ENDIF
	
	nFrete          := 0
	nSeguro         := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VSeg:Text")<>"U", Val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VSeg:Text), 0)
	nIcmsSubs       := IF(TYPE("oxml:_INFNFE:_TOTAL:_ICMSTOT:_VST:Text")<>"U", Val(oxml:_INFNFE:_TOTAL:_ICMSTOT:_VST:Text), 0)
	
	For nCont := 1 to nNumItens
		cCodBarra   := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_CEAN:Text")<>"U", oxml:_INFNFE:_DET[nCont]:_Prod:_CEAN:Text, "")
		cPROCLI     := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_CPROD:Text")<>"U", AllTrim(oxml:_INFNFE:_DET[nCont]:_Prod:_CPROD:Text), "")
		cPRODES     := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text")<>"U", AllTrim(oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text), "")
		
		nQuant      := IF(TYPE("oxml:_INFNFE:_TRANSP:_VOL:_QVOL:Text")<>"U", Val(oxml:_INFNFE:_TRANSP:_VOL:_QVOL:Text), 0)
		
		IF TYPE("oxml:_INFNFE:_COBR[nCont]:_Prod:_PESOB:Text") <> "U"               
			nPESO       := Val(oxml:_INFNFE:_TRANSP[nCont]:_Prod:_PESOB:Text)
		ELSE
			nPESO       := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_QCOM:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_QCOM:Text), 0)			
		ENDIF			
		
		//nPESO       := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_QCOM:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_QCOM:Text), 0)
		//nPESO       := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_PESOB:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_PESOB:Text), 0)   
				
		nPrcUnLiq   := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_VUNCOM:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_VUNCOM:Text), 0)
		nPrcTtLiq   := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_VPROD:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_VPROD:Text), 0)
		nPrcTtBrt   := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_VPROD:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_VPROD:Text), 0)
		nPrcUnBrt   := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_VUNCOM:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_VUNCOM:Text), 0)
		nPrcTtBrt   := nQuant * nPrcUnBrt //Val(oxml:_INFNFE:_DET[nCont]:_Prod:_VPROD:Text)
		cDescItem   := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text")<>"U", AllTrim(oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text), "")
		
		IF TYPE("oxml:_InfNfe:_DET[nCont]:_PROD")<>"U"
			If XmlChildEx(oxml:_InfNfe:_DET[nCont]:_PROD, "_VDESC")!= Nil
				nValDesc:= IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_VDESC:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_VDESC:Text), 0)
			Else
				nValDesc:= 0
			EndIf
		ELSE
			nValDesc:= 0
		ENDIF
		
		/*------------------------------------------------------------------------+
		|VERIFICA SE EXISTE PRODUTO RELACIONADO                                   |
		+------------------------------------------------------------------------*/
		DE7->(DBSETORDER(2))
		
		IF DE7->(DBSEEK(xFILIAL("DE7")+cCODCLI+cLOJCLI+cPROCLI))
		
			cCODIGO := DE7->DE7_CODPRO        		  
			
			SB1->(DBSETORDER(1))
			cCODEMB := IF(SB1->(DBSEEK(xFILIAL("SB1")+cCODIGO)), SB1->B1_UM,  "")
			
		ELSEIF DE7->(DBSEEK(xFILIAL("DE7")+cCODCLI+cLOJCLI+"*"))
	 
			cCODIGO := DE7->DE7_CODPRO        		  
			
			SB1->(DBSETORDER(1))
			cCODEMB := IF(SB1->(DBSEEK(xFILIAL("SB1")+cCODIGO)), SB1->B1_UM,  "")
				
		ELSE                        

			SB1->(DBSETORDER(3))
			cCODIGO := IF(SB1->(DBSEEK(xFILIAL("SB1")+cPRODES)), SB1->B1_COD, CADPROD(cPROCLI))
			 			
			SB1->(DBSETORDER(1))
			cCODEMB := IF(SB1->(DBSEEK(xFILIAL("SB1")+cCODIGO)), SB1->B1_UM,  "")
			
			IF EMPTY(cCODIGO)
			            
				cLOG += "O produto "+'"'+IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text")<>"U",;
		 		AllTrim(oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text), "")+'"'+" não está amarrado ao cliente!!! "+;
 				"Favor cadastrar o produto na rotina Produto x Embarcador."+CHR(13)+CHR(10)
 				lPRODUTO := .F. 				
				
			ELSE
			
				RECLOCK("DE7",.T.)
				DE7->DE7_FILIAL := xFILIAL("DE7")
				DE7->DE7_CODCLI := cCODCLI
				DE7->DE7_LOJCLI := cLOJCLI
				DE7->DE7_CODPRO := cCODIGO
				DE7->DE7_PRDEMB := cPROCLI
				DE7->DE7_DSCEMB := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text") <> "U", AllTrim(oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text), "")
				DE7->(MSUNLOCK())
				
			ENDIF    
			
		ENDIF

		SB1->(DBSETORDER(1))
		SB1->(DBSEEK(xFILIAL("SB1")+cCODIGO))
		
		nFator := 1
		Do Case
			Case cUnidad = "2"
				nFator := SB1->B1_CONV
			Case cUnidad = "3" .and. SLK->LK_QUANT > 1
				nFator := SLK->LK_QUANT
		EndCase
		
		//Verifica se possui Node _Med
		IF TYPE("oxml:_INFNFE:_DET[nCont]:_Prod")<>"U"
			bMed := XmlChildEx(oxml:_INFNFE:_DET[nCont]:_Prod , "_MED" ) != Nil
		ENDIF
		
		If bMed
			// Converte o Node Med em array para os casos que existe informacao de mais de um lote do mesmo produto.
			If Type("oxml:_InfNfe:_DET[nCont]:_PROD:_MED") = "O"
				XmlNode2Arr(oxml:_InfNfe:_DET[nCont]:_PROD:_MED, "_MED")
				nTotalMed := len(oxml:_InfNfe:_DET[nCont]:_PROD:_MED)
			EndIf
		Else
			nTotalMed := 1
			nQtdeLote := nQuant
			cLote     := ""
			cValidade := ""
		Endif
		// Acumuladores
		nDescTT   := 0
		nValorTT := 0
		AddNFEdi(nCont)
	Next
	
	IF nError == 0                                                   	
//		BEGIN TRANSACTION                                            
		IF lPRODUTO		
			CadNFEdi()
		ENDIF
/*		
		IF !lMSERROAUTO
			cLog := cLog+"F"+ cFilOrig+ " " +cNum+"-> Incluido com sucesso!"+CHR(13)+CHR(10)
		ELSE
			cLog := cLog+"F"+ cFilOrig+ " " +cNum+"-> Erro na Inclusao!"+CHR(13)+CHR(10)
			nError += 1
			
			lMsErroAuto := .F.
			nError += 1
			
			DisarmTransaction() // desfaz as alteracoes ja efetuadas.			
		ENDIF
		   
		END TRANSACTION
*/		
	ENDIF
	
	If nError > 0
		MoverArq(cRAIZ, "Erros", cFile, cFile)
	Else
		MoverArq(cRAIZ, "Importados", cFile, cFile)
		//FRename(cPath+cFile, cPath+substr(cFile,1,at(".xml",cFile)-1) +".imp")
	Endif
ENDIF

nItem      := 0
nErrorItem := 0
aCabec 	   := {}
aItens     := {}
aLinha     := {}

RETURN


/*---------+----------+-------+-----------------------+------+------------+
|Função    |DOCENTCAD | Autor |KENNY ROGER            | Data | 30/01/2015 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |VERIFICA SE O XML JÁ FOI IMPORTADO                            |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION DOCENTCAD()
LOCAL lVALID

DE5->(DBSetOrder(1))

cSerie := PADR(cSerie  , 3, " ")
cNum   := PADR(cNum    , 9, " ")

lVALID := DE5->( dbSeek(xFilial("DE5") + cCNPJEMIT + cNum + cSerie) )

RETURN lVALID

/*---------+----------+-------+-----------------------+------+------------+
|Função    |CADNFEDI  | Autor |KENNY ROGER            | Data | 30/01/2015 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |                                                              |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION CADNFEDI()
LOCAL nL, nI

FOR nL := 1 TO LEN(aITENS)
	RECLOCK("DE5", .T.)	
	FOR nI := 1 TO LEN(aITENS[nL])
		IF VALTYPE(DE5->&(aItens[nL][NI][1])) == "D"
			DE5->&(aItens[nL][NI][1]) := CTOD( aItens[nL][NI][2] )
		ELSE
			DE5->&(aItens[nL][NI][1]) := aItens[nL][NI][2]
		ENDIF
	NEXT	
	DE5->(MSUNLOCK())
NEXT

RETURN

/*---------+----------+-------+-----------------------+------+------------+
|Função    |ADDNFEDI  | Autor |KENNY ROGER            | Data | 30/01/2015 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |                                                              |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION ADDNFEDI(nCONT)
LOCAL cPRODUTO := ""

FOR nI := 1 TO nTotalMed
	nItem++
	aLinha    := {}
		
	if bMed
		cLote     := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_MED[nI]:_NLote:Text")<>"U", oxml:_INFNFE:_DET[nCont]:_Prod:_MED[nI]:_NLote:Text, "")
		cValidade := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_MED[nI]:_DVal:Text")<>"U", oxml:_INFNFE:_DET[nCont]:_Prod:_MED[nI]:_DVal:Text, "")
		cValidade := Substr(cValidade,9,2)+"/"+Substr(cValidade,6,2)+"/"+Substr(cValidade,1,4)
		nQtdeLote := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_MED[nI]:_QLote:Text")<>"U", val(oxml:_INFNFE:_DET[nCont]:_Prod:_MED[nI]:_QLote:Text), 0)
	Endif

	cCfop := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_CFOP:Text")<>"U", oxml:_INFNFE:_DET[nCont]:_Prod:_CFOP:Text, "")
	
	If nContLote != nTotalMed
		nDescLote := Round(nValDesc/nQuant*nQtdeLote,2) // Desconto do Lote Atual
		nValLote  := Round(nPrcTtBrt/nQuant*nQtdeLote,2) // Valor do Lote Atual
		nDescTT   += nDescLote
		nValorTT  += nValLote
	Else
		nDescLote := nValDesc - nDescTT // Desconto do Lote Atual - Diferenca
		nValLote  := nPrcTtBrt - nValorTT // Valor do Lote Atual - Diferenca
	Endif
	
	aadd(aLinha,{"DE5_FILIAL" , xFilial("DE5")})
	aadd(aLinha,{"DE5_EMINFC" , cDtEmissao   	, Nil})
	aadd(aLinha,{"DE5_DTAEMB" , cDtEmissao   	, Nil})
	aadd(aLinha,{"DE5_DOC"    , cNum      		, Nil})
	aadd(aLinha,{"DE5_SERIE"  , cSerNFC    		, Nil})
	aadd(aLinha,{"DE5_CODEMB" , cCODEMB   		, Nil})	
	aadd(aLinha,{"DE5_CFOPNF" , cCfop    		, Nil})
	aadd(aLinha,{"DE5_BASEIC" , nBASEICMS  		, Nil})
	aadd(aLinha,{"DE5_VALICM" , nVALORICMS 		, Nil})
	aadd(aLinha,{"DE5_BASIST" , nBASEIST 		, Nil})
	aadd(aLinha,{"DE5_VALIST" , nVALORIST 		, Nil})
	
	/*------------------------------------------------------------------------+
	| BUSCA PRODUTO NA TABELA CLIENTE X PRODUTO                               |
	+------------------------------------------------------------------------*/	
	DE7->(DBSETORDER(2))
	
	IF DE7->(DBSEEK(xFILIAL("DE7")+cCODCLI+cLOJCLI+cPROCLI))
	
		cPRODUTO := DE7->DE7_CODPRO
		AADD(aLINHA,{"DE5_CODPRO" , DE7->DE7_CODPRO , Nil})
		AADD(aLINHA,{"DE5_CODEMB" , cCODEMB         , Nil})
		
	ELSEIF DE7->(DBSEEK(xFILIAL("DE7")+cCODCLI+cLOJCLI+"*"))
	 
		cPRODUTO := DE7->DE7_CODPRO
		AADD(aLINHA,{"DE5_CODPRO" , DE7->DE7_CODPRO , Nil})
		AADD(aLINHA,{"DE5_CODEMB" , cCODEMB         , Nil})
		
	ENDIF
		
	/*------------------------------------------------------------------------+
	| CASO A UNIDADE DE PESO SEJA TONELADA MULTIPLICA PESO POR MIL            |
	+------------------------------------------------------------------------*/
	IF ALLTRIM(oxml:_INFNFE:_DET[nCONT]:_PROD:_UCOM:TEXT)=="TL"                   
	
		IF TYPE("oxml:_INFNFE:_TRANSP:_VOL:_PESOB:Text") <> "U"               
			AADD(aLINHA,{"DE5_PESO"   , Val(oxml:_INFNFE:_TRANSP:_VOL:_PESOB:Text) * 1000})
		ELSE
			AADD(aLINHA,{"DE5_PESO"   , IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_QCOM:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_QCOM:Text) * 1000, 0)})
		ENDIF			
	
	ELSE

		IF TYPE("oxml:_INFNFE:_TRANSP:_VOL:_PESOB:Text") <> "U"               
			AADD(aLINHA,{"DE5_PESO"   , Val(oxml:_INFNFE:_TRANSP:_VOL:_PESOB:Text)})
		ELSE
			AADD(aLINHA,{"DE5_PESO"   , IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_QCOM:Text")<>"U", Val(oxml:_INFNFE:_DET[nCont]:_Prod:_QCOM:Text), 0)})
		ENDIF			
	
	ENDIF		
/*	
	IF ALLTRIM(oxml:_INFNFE:_DET[nCONT]:_PROD:_UCOM:TEXT)=="TL"                   
		//	AADD(aLINHA,{"DE5_PESO"   , IF(TYPE("oxml:_INFNFE:_DET[nCONT]:_PROD:_QCOM:TEXT")<>"U", VAL(oxml:_INFNFE:_DET[nCONT]:_PROD:_QCOM:TEXT), 0)*1000, Nil}) 
		AADD(aLINHA,{"DE5_PESO"   , IF(TYPE("oxml:_INFNFE:_TRANSP[nCONT]:_PROD:_PESOB:TEXT")<>"U", VAL(oxml:_INFNFE:_TRANSP[nCONT]:_PROD:_PESOB:TEXT), 0)*1000, Nil})
	ELSE
	   //	AADD(aLINHA,{"DE5_PESO"   , IF(TYPE("oxml:_INFNFE:_DET[nCONT]:_PROD:_QCOM:TEXT")<>"U", VAL(oxml:_INFNFE:_DET[nCONT]:_PROD:_QCOM:TEXT), 0)     , Nil}) 
	   	AADD(aLINHA,{"DE5_PESO"   , IF(TYPE("oxml:_INFNFE:_TRANSP[nCONT]:_PROD:_PESOB:TEXT")<>"U", VAL(oxml:_INFNFE:_TRANSP[nCONT]:_PROD:_PESOB:TEXT), 0)     , Nil})
	ENDIF        
*/	
	AADD(aLINHA,{"DE5_QTDVOL" , IF(TYPE("oxml:_INFNFE:_TRANSP:_VOL:_QVOL:TEXT")<>"U", VAL(oxml:_INFNFE:_TRANSP:_VOL:_QVOL:TEXT), 0)            , Nil})
	AADD(aLINHA,{"DE5_VALOR"  , IF(TYPE("oxml:_INFNFE:_DET[nCONT]:_Prod:_VPROD:TEXT")<>"U", VAL(oxml:_INFNFE:_DET[nCONT]:_Prod:_VPROD:TEXT), 0) +;
	IF(TYPE("oxml:_INFNFE:_DET[nCONT]:_imposto:_ICMS:_ICMS10:_vICMSST:TEXT")<>"U", VAL(oxml:_INFNFE:_DET[nCONT]:_imposto:_ICMS:_ICMS10:_vICMSST:TEXT), 0)     , Nil})
//	AADD(aLINHA,{"DE5_PLACA"  , IF(TYPE("oxml:_INFNFE:_TRANSP:_VEICTRANSP:_PLACA:TEXT")<>"U", ALLTRIM(oxml:_INFNFE:_TRANSP:_VEICTRANSP:_PLACA:TEXT), 0), Nil})
	/*------------------------------------------------------------------------+
	| CASO PAGADOR DE FRETE SEJA 0-EMITENTE FRETE CIF                         |
	+------------------------------------------------------------------------*/
	IF TYPE("oxml:_INFNFE:_TRANSP:_MODFRETE:TEXT")<>"U"
		IF ALLTRIM(oxml:_INFNFE:_TRANSP:_MODFRETE:TEXT)=="0"
			AADD(aLINHA,{"DE5_TIPFRE", "1"       , NIL})
			AADD(aLINHA,{"DE5_CGCDEV", cCNPJEMIT , NIL})
		ELSE
			AADD(aLINHA,{"DE5_TIPFRE", "2"       , NIL})
			AADD(aLINHA,{"DE5_CGCDEV", cCNPJDEST , NIL})
		ENDIF
	ELSE
		AADD(aLINHA,{"DE5_TIPFRE", "1"       , NIL})
		AADD(aLINHA,{"DE5_CGCDEV", cCNPJEMIT , NIL})
	ENDIF
	AADD(aLINHA,{"DE5_TIPTRA" , "1" , NIL})
	AADD(aLINHA,{"DE5_STATUS" , "1" , NIL})
	
	SA1->(DBSETORDER(3))
	IF !(SA1->(DBSEEK(xFILIAL("SA1")+cCNPJDEST)))
		CADDEST()
	ENDIF
	
	aadd(aLinha,{"DE5_CGCREM" , cCNPJEMIT	, Nil})
	//aadd(aLinha,{"DE5_INSREM" , cIE_Emit	, Nil})
	aadd(aLinha,{"DE5_CGCDES" , cCNPJDEST	, Nil})
	aadd(aLinha,{"DE5_NFEID"  , cChave		, Nil}) //Chave NF-e
	
	nPOSA := ASCAN(aLINHA, {|X| ALLTRIM(X[1]) == "DE5_FILIAL"})
	nPOSB := ASCAN(aLINHA, {|X| ALLTRIM(X[1]) == "DE5_CGCREM"})
	nPOSC := ASCAN(aLINHA, {|X| ALLTRIM(X[1]) == "DE5_DOC"})
	nPOSD := ASCAN(aLINHA, {|X| ALLTRIM(X[1]) == "DE5_SERIE"})
	nPOSE := ASCAN(aLINHA, {|X| ALLTRIM(X[1]) == "DE5_CODPRO"})
	
	nPOSF := ASCAN(aITENS, {|X| X[nPOSA][2] + X[nPOSB][2] + X[nPOSC][2] + X[nPOSD][2] + X[nPOSE][2] == xFILIAL("DE5") + cCNPJEMIT + cNum + cSerNFC + cPRODUTO})
				
	IF nPOSF > 0
	
		aITENS[nPOSF][ASCAN(aLINHA, {|X| ALLTRIM(X[1]) == "DE5_VALOR"})][2]  += aLINHA[ASCAN(aLINHA, {|X| ALLTRIM(X[1]) == "DE5_VALOR"})][2]
		
	ELSE
		
		aadd(aItens,aLinha)
		
	ENDIF	
	
NEXT

RETURN

/*---------+----------+-------+-----------------------+------+------------+
|Função    |CADPROD   | Autor |KENNY ROGER            | Data | 30/01/2015 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |                                                              |
+----------+--------------------------------------------------------------+
|Uso       |COMPRAS / TMS                                                 |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION CADPROD(cCODIGO)
LOCAL lADD    := GETNEWPAR("ZZ_EDIPROD",.F.) 
LOCAL lAUTO   := GETNEWPAR("ZZ_EDIAUTO",.F.)

IF lADD

	IF lAUTO
	
		cCODIGO := GETSXENUM("SB1")
		
		SB1->(DBSETORDER(1))
			
		WHILE SB1->(MSSEEK(XFILIAL("SB1") + cCODIGO))			
			SB1->(CONFIRMSX8())
			cCODIGO := GETSXENUM("SB1")
		ENDDO
	
		SB1->(CONFIRMSX8())
		
	ENDIF	
		
	RECLOCK("SB1",.T.)
	SB1->B1_FILIAL  := xFilial("SB1")
	SB1->B1_COD     := cCODIGO
	SB1->B1_DESC    := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text")<>"U", AllTrim(oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text), "")
	SB1->B1_UM      := IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_UCOM:Text")<>"U", oxml:_INFNFE:_DET[nCont]:_Prod:_UCOM:Text, "")
	SB1->B1_TIPO    := "PA"
	SB1->B1_LOCPAD  := "01"
	SB1->(MSUNLOCK())
	
ELSE

	nERROR++
	cLOG += "O produto "+'"'+IF(TYPE("oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text")<>"U",;
	 		AllTrim(oxml:_INFNFE:_DET[nCont]:_Prod:_XPROD:Text), "")+'"'+" não está amarrado ao cliente!!!"+;
	 		"Favor cadastrar o produto na rotina Produto x Embarcador."+CHR(13)+CHR(10)
	 		
ENDIF

RETURN cCODIGO

/*---------+----------+-------+-----------------------+------+------------+
|Função    |CADEMIT   | Autor |KENNY ROGER            | Data | 30/01/2015 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |CADASTRA DE EMITENTE                                          |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION CADEMIT()
LOCAL cCODCLI
LOCAL cLOJCLI
LOCAL cCNPJEMIT := IF(TYPE("oxml:_INFNFE:_EMIT:_CNPJ:TEXT")<>"U", oxml:_INFNFE:_EMIT:_CNPJ:TEXT, "")        
                                                                   
nERROR++
cLOG += "O emitente "+'"'+cCNPJEMIT+'"'+" não está cadastrado!"+CHR(13)+CHR(10)

//cCODCLI := IF(GETLOJA(cCNPJEMIT)[2]=="01", GETSXENUM("SA1"), GETLOJA(cCNPJEMIT)[1])
  
IF GETLOJA(cCNPJDEST)[2] == "01"

	cCODCLI := GETSXENUM("SA1")
	
	SA1->(DBSETORDER(1))
			
	WHILE SA1->(MSSEEK(XFILIAL("SA1") + cCODCLI))			
		SA1->(CONFIRMSX8())
		cCODCLI := GETSXENUM("SA1")
	ENDDO
	
	SA1->(CONFIRMSX8())	
					
ELSE

	cCODCLI := GETLOJA(cCNPJDEST)[1]
	
ENDIF	

cLOJCLI := GETLOJA(cCNPJEMIT)[2]
cCODMUN := IF(TYPE("oxml:_INFNFE:_DEST:_ENDERDEST:_CMUN:TEXT")<>"U", oxml:_INFNFE:_DEST:_ENDERDEST:_CMUN:TEXT, "")
                                               
CONFIRMSX8()

RECLOCK("SA1", .T.)
SA1->A1_FILIAL 	:= xFILIAL("SA1")
SA1->A1_COD     := cCODCLI
SA1->A1_LOJA    := cLOJCLI
SA1->A1_TIPO    := "F"
SA1->A1_PESSOA  := "J"
SA1->A1_CGC     := cCNPJEMIT
SA1->A1_NOME    := IF(TYPE("oxml:_INFNFE:_EMIT:_XNOME:TEXT")<>"U", oxml:_INFNFE:_EMIT:_XNOME:TEXT, "")
SA1->A1_NREDUZ  := IF(TYPE("oxml:_INFNFE:_EMIT:_XFANT:TEXT")<>"U", oxml:_INFNFE:_EMIT:_XFANT:TEXT, "")
SA1->A1_PAIS    := IF(TYPE("oxml:_INFNFE:_EMIT:_ENDEREMIT:_CPAIS:TEXT")<>"U", oxml:_INFNFE:_EMIT:_ENDEREMIT:_CPAIS:TEXT, "")
SA1->A1_END     := IF(TYPE("oxml:_INFNFE:_EMIT:_ENDEREMIT:_XLGR:TEXT")<>"U", oxml:_INFNFE:_EMIT:_ENDEREMIT:_XLGR:TEXT, "")
SA1->A1_EST     := IF(TYPE("oxml:_INFNFE:_EMIT:_ENDEREMIT:_UF:TEXT")<>"U", oxml:_INFNFE:_EMIT:_ENDEREMIT:_UF:TEXT, "")
SA1->A1_COD_MUN := IF(LEN(cCODMUN) == 7, SUBSTR(cCODMUN, 3, 5), cCODMUN)
SA1->A1_MUN     := IF(TYPE("oxml:_INFNFE:_EMIT:_ENDEREMIT:_XMUN:TEXT")<>"U", oxml:_INFNFE:_EMIT:_ENDEREMIT:_XMUN:TEXT, "")
SA1->A1_BAIRRO  := IF(TYPE("oxml:_INFNFE:_EMIT:_ENDEREMIT:_XBAIRRO:TEXT")<>"U", oxml:_INFNFE:_EMIT:_ENDEREMIT:_XBAIRRO:TEXT, "")
SA1->A1_CEP     := IF(TYPE("oxml:_INFNFE:_EMIT:_ENDEREMIT:_CEP:TEXT")<>"U", oxml:_INFNFE:_EMIT:_ENDEREMIT:_CEP:TEXT, "")
SA1->A1_TEL     := IF(TYPE("oxml:_INFNFE:_EMIT:_ENDEREMIT:_FONE:TEXT")<>"U", oxml:_INFNFE:_EMIT:_ENDEREMIT:_FONE:TEXT, "")
SA1->A1_INSCR   := IF(TYPE("oxml:_INFNFE:_EMIT:_IE:TEXT")<>"U", oxml:_INFNFE:_EMIT:_IE:TEXT, "") 
SA1->A1_CDRDES  := POSICIONE("DUY", 6, xFILIAL("DUY") + SA1->(A1_EST + A1_COD_MUN), "DUY_GRPVEN")
SA1->(MSUNLOCK())

RETURN

/*---------+----------+-------+-----------------------+------+------------+
|Função    |CADDEST   | Autor |KENNY ROGER            | Data | 30/01/2015 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |CADASTRA DE DESTINATARIO                                      |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION CADDEST()
LOCAL cCODCLI
LOCAL cLOJCLI
LOCAL cCNPJDEST := IF(TYPE("oxml:_INFNFE:_DEST:_CNPJ:TEXT")<>"U", oxml:_INFNFE:_DEST:_CNPJ:TEXT, "")

nERROR++
cLOG += "O destinatário "+'"'+cCNPJDEST+'"'+" não está cadastrado!"+CHR(13)+CHR(10)

//cCODCLI := IF(GETLOJA(cCNPJDEST)[2]=="01", GETSXENUM("SA1"), GETLOJA(cCNPJDEST)[1])     

IF GETLOJA(cCNPJDEST)[2]=="01"
	cCODCLI := GETSXENUM("SA1")
	SA1->(CONFIRMSX8())
ELSE
	cCODCLI := GETLOJA(cCNPJDEST)[1]
ENDIF	

cLOJCLI := GETLOJA(cCNPJDEST)[2]
cCODMUN := IF(TYPE("oxml:_INFNFE:_DEST:_ENDERDEST:_CMUN:TEXT")<>"U", oxml:_INFNFE:_DEST:_ENDERDEST:_CMUN:TEXT, "")

RECLOCK("SA1", .T.)
SA1->A1_FILIAL 	:= xFILIAL("SA1")
SA1->A1_COD     := cCODCLI
SA1->A1_LOJA    := cLOJCLI
SA1->A1_TIPO    := "F"
SA1->A1_PESSOA  := "J"
SA1->A1_CGC     := cCNPJDEST
SA1->A1_NOME    := IF(TYPE("oxml:_INFNFE:_DEST:_XNOME:TEXT")<>"U", oxml:_INFNFE:_DEST:_XNOME:TEXT, "")
SA1->A1_NREDUZ  := IF(TYPE("oxml:_INFNFE:_DEST:_XFANT:TEXT")<>"U", oxml:_INFNFE:_DEST:_XFANT:TEXT, "")
SA1->A1_PAIS    := IF(TYPE("oxml:_INFNFE:_DEST:_ENDERDEST:_CPAIS:TEXT")<>"U", oxml:_INFNFE:_DEST:_ENDERDEST:_CPAIS:TEXT, "")
SA1->A1_END     := IF(TYPE("oxml:_INFNFE:_DEST:_ENDERDEST:_XLGR:TEXT")<>"U", oxml:_INFNFE:_DEST:_ENDERDEST:_XLGR:TEXT, "")
SA1->A1_EST     := IF(TYPE("oxml:_INFNFE:_DEST:_ENDERDEST:_UF:TEXT")<>"U", oxml:_INFNFE:_DEST:_ENDERDEST:_UF:TEXT, "")
SA1->A1_COD_MUN := IF(LEN(cCODMUN) == 7, SUBSTR(cCODMUN, 3, 5), cCODMUN)
SA1->A1_MUN     := IF(TYPE("oxml:_INFNFE:_DEST:_ENDERDEST:_XMUN:TEXT")<>"U", oxml:_INFNFE:_DEST:_ENDERDEST:_XMUN:TEXT, "")
SA1->A1_BAIRRO  := IF(TYPE("oxml:_INFNFE:_DEST:_ENDERDEST:_XBAIRRO:TEXT")<>"U", oxml:_INFNFE:_DEST:_ENDERDEST:_XBAIRRO:TEXT, "")
SA1->A1_CEP     := IF(TYPE("oxml:_INFNFE:_DEST:_ENDERDEST:_CEP:TEXT")<>"U", oxml:_INFNFE:_DEST:_ENDERDEST:_CEP:TEXT, "")
SA1->A1_TEL     := IF(TYPE("oxml:_INFNFE:_DEST:_ENDERDEST:_FONE:TEXT")<>"U", oxml:_INFNFE:_DEST:_ENDERDEST:_FONE:TEXT, "")
SA1->A1_INSCR   := IF(TYPE("oxml:_INFNFE:_DEST:_IE:TEXT")<>"U", oxml:_INFNFE:_DEST:_IE:TEXT, "")     
SA1->A1_CDRDES  := POSICIONE("DUY", 6, xFILIAL("DUY") + SA1->(A1_EST + A1_COD_MUN), "DUY_GRPVEN")
SA1->(MSUNLOCK())

RETURN

/*---------+----------+-------+-----------------------+------+------------+
|Função    |NUMLOJA   | Autor | KENNY ROGER           | Data | 30/01/2015 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |RETORNA SEQUENCIA DA LOJA                                     |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION GETLOJA(cCNPJ)
LOCAL cLOJA   := "01"
LOCAL cCODIGO := ""
LOCAL cRAIZCNPJ
LOCAL cSQL
LOCAL qQUERY

cRAIZCNPJ := SUBSTR(cCNPJ, 1, 8)

cSQL := "   SELECT A1_COD, MAX(A1_LOJA) NOVALOJA"
cSQL += "     FROM " + RETSQLNAME("SA1")
cSQL += "    WHERE A1_CGC LIKE '" + cRAIZCNPJ + "%'"
cSQL += "      AND   D_E_L_E_T_  = ''"
cSQL += " GROUP BY A1_COD"
TCQUERY cSQL NEW ALIAS qQUERY

WHILE qQUERY->(!EOF())
	cCODIGO := qQUERY->(A1_COD)
	cLOJA   := SOMA1(qQUERY->(NOVALOJA))
	qQUERY->(DBSKIP())
ENDDO                         

qQUERY->(DBCLOSEAREA())

RETURN {cCODIGO, cLOJA}

/*---------+----------+-------+-----------------------+------+------------+
|Função    |MOVERARQ  | Autor |KENNY ROGER            | Data | 30/01/2015 |
+----------+----------+-------+-----------------------+------+------------+
|Descrição |ROTINA PARA MOVER O ARQUIVO DEPOIS DE PROCESSADO              |
+----------+--------------------------------------------------------------+
|Uso       |TMS                                                           |
+----------+-------------------------------------------------------------*/
STATIC FUNCTION MoverArq(cRAIZ, cDiretorio, cArqOrig, cArqDest)
LOCAL nRET := 0

IF !EXISTDIR(cRAIZ+cDiretorio)
	nRET := MAKEDIR(cRAIZ+cDiretorio)
ENDIF

IF nRET != 0
	CONOUT( 'Não foi possível criar o diretório "'+cDiretorio+'".' )
ELSE
	IF FRENAME(cRAIZ+cArqDest, cRAIZ+cDiretorio+"\"+cArqDest) == -1
		CONOUT("O sistema não moveu o arquivo")
	ENDIF
ENDIF

RETURN
