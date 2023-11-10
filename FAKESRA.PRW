#INCLUDE "PROTHEUS.CH"
/*{Protheus.doc} FakeSRA

Cria funcionarios novos baseado em um modelo pré-existente.
@author Leandro Drumond
*/
User Function FakeSRA()
Local aArea  	:= GetArea()
Local aSRAFields:= {}
Local aPerFerias:= {}
Local cAliasQry := GetNextAlias()
Local nX		:= 0
Local nY		:= 0
Local nZ		:= 0
Local lCriaSRD	:= .F.					//Se deve criar registros na SRD para os fakes
Local lCriaSRF  := .T. 					//Se deve criar SRF
Local lCriaMnemo:= .T.
Local dDataLim  := CtoD("31/08/2023") 	//Data limite para criação da SRF
Local cAnoSRD	:= "2023"				//Ano para criação dos registros na SRD
Local aFakes	:= {10, 0, 0, 0}		//Número de funcionários que serão criados por filial
Local aFiliais	:= {"D MG 01 ", "D RJ 01 ", "M PR 01 ", "M SP 01 "}		//Filiais onde serão criados os fakes
Local cMatAux	:= "888945"				//Matrícula a partir da qual serão gerados os fakes
Local cMatFake	:= "943002"				//Matrícula inicial para os fakes
Local cIndice	:= "1001"				//Código incluído na frente do nome (RA_NOME)
Local cProcesso	:= "09001"				//Processo dos funcionários fakes

CursorWait()

RpcSetType(3)
RpcSetEnv("T1", "D MG 01",,,"GPE")

OpenProfile()

DbSelectArea("SRA")
DbSetOrder(1)

aSRAFields 	:= dbStruct()

BeginSql alias cAliasQry
	SELECT *
	FROM 		%table:SRA% SRA
	WHERE RA_MAT = %exp:cMatAux%
	ORDER BY RA_MAT				
EndSql

For nX := 1 to Len(aFakes)
	For nZ := 1 to aFakes[nX]

		While .T.
			If SRA->(DbSeek(aFiliais[nX] + cMatFake)) //Se a matrícula já existir, soma 1 e continua buscado até naõ encontrar.
				cMatFake := Soma1(cMatFake)
			Else
				Exit
			EndIf
		EndDo
		
		Conout(".....Fake: " + AllTrim(STR(nZ)))
		RecLock("SRA",.T.)
		
		For nY := 1 to Len(aSRAFields)
			If ValType(SRA->&(aSRAFields[nY,1])) == "D"
				SRA->&(aSRAFields[nY,1]) := StoD((cAliasQry)->&(aSRAFields[nY,1]))
			ElseIf aSRAFields[nY,2] == "M"
				Loop
			Else
				SRA->&(aSRAFields[nY,1]) := (cAliasQry)->&(aSRAFields[nY,1])
			EndIf
		Next nY
		
		SRA->RA_MAT 	:= cMatFake
		SRA->RA_CIC 	:= GeraCPFVld()	//Gera um número de CPF válido
		SRA->RA_PIS 	:= GeraPISVld()	//Gera um número de PIS válido
		SRA->RA_NOME 	:= "FECHAMENTO COM GRID - " + cIndice
		SRA->RA_CATFUNC := "M"
		SRA->RA_PROCES 	:= cProcesso
		SRA->RA_FILIAL 	:= aFiliais[nX]
		SRA->RA_SALARIO := Randomize(5000,10000)
		
		MsUnLock()
		
		If lCriaSRD
			CriaSRDFake((cAliasQry)->RA_FILIAL, (cAliasQry)->RA_MAT,cAnoSRD,cMatFake)
		EndIf

		If lCriaSRF
			If lCriaMnemo
				SetMnemonicos(NIL,NIL,.T.)
				lCriaMnemo := .F.
			EndIf
			aPerFerias	:= {}
			Calc_Fer(@aPerFerias,dDataLim,,,,,,.T.)
			cPdFer := fGetCodFOl("0072",.F.,xFilial("SRV",SRA->RA_FILIAL))

			For nY := 1 to Len(aPerFerias)
				If !SRF->( DbSeek( SRA->RA_FILIAL+SRA->RA_MAT + cPdFer + DtoS(aPerFerias[nY][01]) ) )
					RecLock( "SRF" , .T. )
					SRF->RF_FILIAL	:= SRA->RA_FILIAL
					SRF->RF_MAT		:= SRA->RA_MAT
					SRF->RF_PD		:= cPdFer
					SRF->RF_DIASDIR := 30
					SRF->RF_STATUS	:= "1"
					SRF->RF_DATABAS := aPerFerias[nY][01]
					SRF->RF_DATAFIM := aPerFerias[nY][02]
					SRF->RF_DFERVAT := aPerFerias[nY][03]
					SRF->RF_DFERAAT := aPerFerias[nY][04]
					SRF->RF_DFERANT := aPerFerias[nY][14]
					SRF->RF_DVENPEN := aPerFerias[nY][11]
					SRF->RF_IVENPEN := aPerFerias[nY][12]
					SRF->RF_FVENPEN := aPerFerias[nY][13]
					SRF->RF_DFALVAT := aPerFerias[nY][15]
					SRF->RF_DFALAAT := aPerFerias[nY][16]
					SRF->( MsUnLock() )
				EndIf
			Next nY
		EndIf
		
		cIndice := Soma1(cIndice)
		cMatFake := Soma1(cMatFake)	
	
	Next nZ

Next nX

(cAliasQry)->( DbCloseArea() )

CursorArrow()

Alert("Rotina finalizada!")

RestArea(aArea)

Return Nil

/*{Protheus.doc} GeraCPFVld

Gera um CPF válido

@author Leandro Drumond
*/
Static Function GeraCPFVld()
Local aCpf1		:= Array(9,3)
Local aCpf2 	:= Array(10,3)
Local cCpf		:= ""
Local nX 		:= 0
Local nAux		:= 11
Local nTotAux	:= 0
Local nDig1 	:= 0
Local nDig2 	:= 0

For nX :=1 to 9
	aCpf1[nX,1] := Randomize(0,9) 
	aCpf1[nX,2] := nAux - nX
	aCpf1[nX,3] := aCpf1[nX,2] * aCpf1[nX,1]
	nTotAux += aCpf1[nX,3]   
Next nX

nDig1 := nTotAux % 11

If nDig1 < 2
	nDig1 := 0
Else
	nDig1 := 11 - nDig1
EndIf

nTotAux := 0

For nX := 1 to 9
	aCpf2[nX,1] := aCpf1[nX,1]
	aCpf2[nX,2] := aCpf1[nX,2]+1
	aCpf2[nX,3] := aCpf2[nX,2] * aCpf2[nX,1]
	nTotAux += aCpf2[nX,3] 
Next nX

aCpf2[10,1] := nDig1
aCpf2[10,2] := 2
aCpf2[10,3] := aCpf2[10,2] * aCpf2[10,1]
nTotAux += aCpf2[10,3]

nDig2 := nTotAux % 11

If nDig2 < 2
	nDig2 := 0
Else
	nDig2 := 11 - nDig2
EndIf

For nX := 1 to 9
	cCpf += AllTrim(Str(aCpf1[nX,1]))
Next nX

cCpf += AllTrim(Str(nDig1)) + AllTrim(Str(nDig2))

Return cCpf

/*{Protheus.doc} GeraPISVld

Gera um PIS válido

@author Leandro Drumond
*/
Static Function GeraPISVld()
Local aPIS		:= Array(10,2)
Local aPeso 	:= {3, 2, 9, 8, 7, 6, 5, 4, 3, 2}
Local nX 		:= 0
Local nTotAux	:= 0
Local nDig		:= 0
Local cPIS		:= ""

For nX :=1 to 10
	aPIS[nX,1] := Randomize(0,9) 
	aPIS[nX,2] := aPeso[nX] * aPIS[nX,1]
	nTotAux += aPIS[nX,2]   
Next nX

nDig := 11 - (nTotAux % 11)

nDig := If(nDig >= 10, 0, nDig)

For nX := 1 to 10
	cPIS += AllTrim(Str(aPIS[nX,1]))
Next nX

cPIS += AllTrim(Str(nDig))

Return cPIS

/*{Protheus.doc} CriaSRDFake

Duplica os registros da SRD do funcionário original para o fake

@author Leandro Drumond
*/

Static Function CriaSRDFake(cFilAux,cMatAux,cAnoSRD,cNewMat)
Local aArea 		:= GetArea()
Local aSRDFields	:= {}
Local cAliasSRD		:= GetNextAlias()
Local cDataIni		:= cAnoSrd + "01"		//Período inicial para a geração dos registros
Local cDataFim		:= cAnoSrd + "13"		//Período final para a geração dos registros
Local nX			:= 0

DbSelectArea("SRD")
DbSetOrder(1)

aSRDFields := DbStruct()

BeginSql alias cAliasSRD
	SELECT 		*
	FROM 		%table:SRD% SRD
	WHERE 	RD_FILIAL = %exp:cFilAux%  AND
			RD_MAT = %exp:cMatAux% AND
			RD_DATARQ >= %exp:cDataIni% AND
			RD_DATARQ <= %exp:cDataFim% AND
			SRD.%NotDel%
	ORDER BY RD_PD,RD_SEQ				
EndSql

While (cAliasSRD)->(!Eof())
	RecLock("SRD",.T.)
	For nX := 1 to Len(aSRDFields)
		If ValType(SRD->&(aSRDFields[nX,1])) == "D"
			SRD->&(aSRDFields[nX,1]) := StoD((cAliasSRD)->&(aSRDFields[nX,1]))
		Else
			SRD->&(aSRDFields[nX,1]) := (cAliasSRD)->&(aSRDFields[nX,1])
		EndIf
	Next nX
	SRD->RD_MAT := cNewMat
	MsUnLock()
	(cAliasSRD)->(DbSkip())
EndDo

(cAliasSRD)->(DbCloseArea())

RestArea(aArea)

Return Nil

//Duplicar SRC
User Function DupSRC()

Local aArea  	:= GetArea()
Local aSRCFields:= {}
Local cAliasQry := GetNextAlias()
Local nReg		:= 0
Local nY 		:= 0
Local cProcesso	:= "01415"				//Processo dos funcionários fakes
Local cPeriodo  := "198001"

CursorWait()

RpcSetType(3)
RpcSetEnv("T1", "D MG 02",,,"GPE")

OpenProfile()

DbSelectArea("SRC")
DbSetOrder(1)

aSRCFields 	:= dbStruct()

BeginSql alias cAliasQry
	SELECT *
	FROM 		%table:SRC% SRC
	WHERE RC_PROCES = %exp:cProcesso%
	ORDER BY RC_MAT				
EndSql

While (cAliasQry)->(!Eof())

	cPeriodo  := "198001"

	While cPeriodo < "202301"

		nReg++

		RecLock("SRC",.T.)
		
		For nY := 1 to Len(aSRCFields)
			If ValType(SRC->&(aSRCFields[nY,1])) == "D"
				SRC->&(aSRCFields[nY,1]) := StoD((cAliasQry)->&(aSRCFields[nY,1]))
			ElseIf aSRCFields[nY,2] == "M"
				Loop
			Else
				SRC->&(aSRCFields[nY,1]) := (cAliasQry)->&(aSRCFields[nY,1])
			EndIf
		Next nY

		SRC->RC_PERIODO	:= cPeriodo

		Conout(".....Fake: " + AllTrim(STR(nReg)))

		MsUnLock()
		
		cPeriodo := SomaMesAno( cPeriodo )

	EndDo

	(cAliasQry)->( DbSkip() )

EndDo

(cAliasQry)->( DbCloseArea() )

CursorArrow()

RestArea(aArea)

Return Nil

//Duplicar rgb
User Function DupRGB()

Local aArea  	:= GetArea()
Local aRGBFields:= {}
Local cAliasQry := GetNextAlias()
Local nReg		:= 0
Local nY 		:= 0
Local cProcesso	:= "01415"				//Processo dos funcionários fakes
Local cPeriodo  := "198001"

CursorWait()

RpcSetType(3)
RpcSetEnv("T1", "D MG 02",,,"GPE")

OpenProfile()

DbSelectArea("RGB")
DbSetOrder(1)

aRGBFields 	:= dbStruct()

BeginSql alias cAliasQry
	SELECT *
	FROM 		%table:RGB% RGB
	WHERE RGB_PROCES = %exp:cProcesso%
	ORDER BY RGB_MAT				
EndSql

nReg := 0

While (cAliasQry)->(!Eof())

	cPeriodo  := "198001"

	While cPeriodo < "202301"

		nReg++

		RecLock("RGB",.T.)
		
		For nY := 1 to Len(aRGBFields)
			If ValType(RGB->&(aRGBFields[nY,1])) == "D"
				RGB->&(aRGBFields[nY,1]) := StoD((cAliasQry)->&(aRGBFields[nY,1]))
			ElseIf aRGBFields[nY,2] == "M"
				Loop
			Else
				RGB->&(aRGBFields[nY,1]) := (cAliasQry)->&(aRGBFields[nY,1])
			EndIf
		Next nY

		RGB->RGB_PERIOD	:= cPeriodo

		Conout(".....Fake RGB: " + AllTrim(STR(nReg)))

		MsUnLock()
		
		cPeriodo := SomaMesAno( cPeriodo )

	EndDo

	(cAliasQry)->( DbSkip() )

EndDo

(cAliasQry)->( DbCloseArea() )

CursorArrow()

RestArea(aArea)

Return Nil
