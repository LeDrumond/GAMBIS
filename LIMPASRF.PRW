#INCLUDE "PROTHEUS.CH"
/*{Protheus.doc} LimpaSRF

Deixa apenas o último período aquisitivo na SRF, excluindo todos os demais.
@author Leandro Drumond
*/

User Function LimpaSRF()

Local cFilMat := ""

DbSelectArea("SRF")
DbSetOrder(1)
DbGoTop()

While SRF->(!Eof())
	If Empty(cFilMat)
		cFilMat := SRF->RF_FILIAL + SRF->RF_MAT
	EndIf
	SRF->(DbSkip())
	If SRF->(Eof())
		Exit
	EndIf
	If cFilMat == SRF->RF_FILIAL + SRF->RF_MAT
		SRF->(DbSkip(-1))
		RecLock("SRF",.F.)
		DbDelete()
		MsUnLock()
		SRF->(DbSkip())
	Else
		cFilMat := SRF->RF_FILIAL + SRF->RF_MAT
	EndIf
EndDo

Return Nil