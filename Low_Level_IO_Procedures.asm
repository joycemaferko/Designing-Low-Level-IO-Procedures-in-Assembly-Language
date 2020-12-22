TITLE Designing Low-Level I/O Procedures using Microsoft Macro Assembler (MASM) Assembly Language

; Author: Matt Joyce
; Last Modified: 06/07/2020
; email: joycema@oregonstate.edu
; Description: The program will 1) Design and implement new ReadVal (input) and WriteVal (output) procedures 
; for signed integers. 2) Design and implement macros getString and displayString to facilitate new I/O procedures. 
; The procedures and macros will convert string values to numeric values and numeric values back to string. 3) Write 
; a small test program that gets 10 valid integers from the user and stores the numeric values in an array. The 
; program then displays the integers, their sum, and their average. Integer array is displayed in numeric form, 
; sum and average are displayed in string form. 

INCLUDE Irvine32.inc

; macro prompts user for input, saves string input to memory location
; receives: offset of prompt, offset of memory location (calling procedure pushes these by reference) 
; preconditions: memory location should be defined in data segment
; returns: Ascii character string saved in memory
getString		MACRO	prompt, buffer
	push	edx
	push	ecx
	mov		edx,	prompt
	call	WriteString
	mov		edx,	buffer
	mov		ecx, MAXSIZE
	call	ReadString
	pop		ecx
	pop		edx
ENDM

; macro prints contents of string to console
; receives: offset of memory location (calling procedure pushes this by reference) 
; preconditions: memory location should be defined in data segment, string should be filled with character values.
; returns: string printed to console
displayString	MACRO	buffer
	push	edx
	mov		edx, buffer
	call	WriteString
	pop		edx
ENDM

MAXSIZE = 100

.data
	
	intro1		SBYTE	"Designing Low-Level I/O Procedures: ", 0
	intro2		SBYTE	"Programmed by Matt Joyce ", 0
	intro3		SBYTE	"When I say go, enter 10 signed decimal integers. ", 0
	intro4		SBYTE	"Each integer should be small enought to fit inside a 32-bit register. ", 0
	intro5		SBYTE	"The program will then display the integers, their sum, and their average. ", 0
	prompt1		SBYTE	"GO! ", 0
	string1		SDWORD	MAXSIZE DUP(?)
	string2		SDWORD	MAXSIZE DUP(?) 
	string3		SDWORD	MAXSIZE	DUP(?)
	string4		SDWORD	MAXSIZE DUP(?)
	string5		SDWORD	MAXSIZE DUP(?)
	string6		SDWORD	MAXSIZE	DUP(?)
	string7		SDWORD	MAXSIZE	DUP(?)
	error1		SBYTE	"ERROR: You did not enter a signed integer or your number does not fit into the register. ", 0
	num_inputs	SDWORD	?
	user_int	SDWORD	?	
	spacer		SDWORD	"  ", 0
	list_label1	SBYTE	"The integers you have entered are: ",0
	list_sum	SDWORD	?
	list_avg	SDWORD	?
	sum_label	SBYTE	"The sum is: ", 0
	avg_label	SBYTE	"The rounded average is: ", 0
	goodbye		SBYTE	"Come back any time! ", 0
	minus_label	SBYTE	"-",0


.code
main PROC
	
	; introduces program and provides instructions to user
	push	OFFSET intro5
	push	OFFSET intro4
	push	OFFSET intro3
	push	OFFSET intro2
	push	OFFSET intro1
	call	introduction

	; initializes loop to get 10 integer values into array string5
	mov		ecx, 10
	mov		eax, 0
	mov		edi, OFFSET string5
	
	; loop calls readVal procedure 10 times, each iteration puts a numeric integer value into string5
intArrayLoop:
	push	OFFSET	string2
	push	OFFSET	error1
	push	OFFSET	prompt1
	push	OFFSET	string1
	call	readVal
	stosd ; moves value from eax to string5
	loop	intArrayLoop

	; print contents of numeric integer array
	push	OFFSET	list_label1
	push	OFFSET  spacer
	push	OFFSET	string5
	call	displayList

	; calculates sum and average of numeric integer array
	push	OFFSET	list_avg
	push	OFFSET	list_sum
	push	OFFSET	string5
	call	sumAndAverage

	; call to writeVal to display list_sum as string
	push	OFFSET	minus_label
	push	OFFSET	string4
	push	OFFSET	sum_label
	push	OFFSET	string3
	push	list_sum
	call	writeVal

	; call to writeVal to display List_avg as string
	push	OFFSET	minus_label
	push	OFFSET	string7
	push	OFFSET	avg_label
	push	OFFSET	string6
	push	list_avg
	call	writeVal

	; close out program
	push	OFFSET	goodbye
	call	farewell

	exit	; exit to operating system
main ENDP

;Procedure to introduce the program.
;receives: offsets of introduction strings 1 through 5
;returns: none
;preconditions:  none
;registers changed: edx
introduction	PROC
	; set up stack frame, save registers
	push	ebp
	mov		ebp, esp
	push	edx

	; Print intro1 - intro5
	mov		edx, [ebp + 8] ; @intro1
	call	WriteString
	call	CrLf
	mov		edx, [ebp + 12] ; @intro2
	call	WriteString
	call	CrLf
	call	CrLf
	mov		edx, [ebp + 16] ; @intro3
	call	WriteString
	call	CrLf
	mov		edx, [ebp + 20] ; @intro4
	call	WriteString
	call	CrLf
	mov		edx, [ebp +24] ; @intro5
	call	WriteString
	call	CrLf
	call	CrLf

	; restore registers, return
	pop		edx
	pop		ebp
	ret		20
introduction	ENDP

;Procedure to convert user's string input to numeric value.
;receives: offsets of string1 and string2, offsets of prompt1, error1, and spacer, offsets of num_inputs and user_int.
;returns: string converted to numeric integer value, saved in array string5.
;preconditions:  getString macro defined to save string values to memory. 
;registers changed: eax, ebx, ecx, edx, esi, edi
;Note: Referenced lecture 23 slides to implement conversion algorithm
readVal		PROC
	; set up stack frame, save values of registers
	push	ebp
	mov		ebp, esp
	sub		esp, 12 ; create local var X, Y, Z
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	
redo: ; allows user to re-enter a new string after an invalid attempt

	; macro displays a prompt and saves user's input into array
	getString	[ebp +12], [ebp + 8] ; @prompt1, @string1

	mov		esi, [ebp + 8] ; @string1
	mov		edi, [ebp + 20] ; @string2
	mov		ecx, eax; counter set to num of vals in array
	mov		eax, 0
	mov		DWORD PTR [ebp-4], 0 ; X = 0
	mov		DWORD PTR [ebp-8], 0 ; Y = 0
	cld		; direction = fwd

	;if the user's first character is "+", skip it and continue loop
	lodsb
	cmp		al, 43
	je		ifPlus
	cmp		al, 45
	je		ifNeg
	jmp		ifNotPlusOrNeg

L2:
	lodsb
	;ensures the character is within ascii value range for numeric values 0-9, otherwise throws error message and re-prompts user for input.
ifNotPlusOrNeg:
	cmp		al, 48
	jl		errorMsg
	cmp		al, 57
	jg		errorMsg
	jmp		contLoop

	; if the first character is plus, decrement the counter and skip the character wihtout converting.
ifPlus:
	dec		ecx
	jmp		L2

contLoop:
	;Conversion from string of digits to numeric value
	sub		al, 48
	mov		[ebp-8], al ; y = (str[k] - 48)
	mov		al, [ebp-4] ; x into al
	imul	eax, 10
	jo		errorMsg ; if overflow flag is set, number is too large to fit in 32 bit register, re-prompt user.
	add		eax, [ebp-8] ; eax reg + y   
	jo		errorMsg ; if overflow flag is set, number is too large to fit in 32 bit register, re-prompt user.
	mov		[ebp-4], eax ; x = 10*x +(str[k]-48)
	loop	L2
	jmp		validInt

	; In case of a leading "-", this loop skips the "-" character, checks to ensure validity of the other characters, 
	; converts integer to 2's complement
L3:
	lodsb
	cmp		al, 48
	jl		errorMsg
	cmp		al, 57
	jg		errorMsg
	jmp		contLoop2

ifNeg:
	dec		ecx
	jmp		L3

contLoop2:
	;Conversion from string of digits to numeric value
	sub		al, 48
	mov		[ebp-8], al ; y = (str[k] - 48)
	mov		al, [ebp-4] ; x into al
	imul	eax, 10
	jo		errorMsg ; if overflow flag is set, number is too large to fit in 32 bit register, re-prompt user for input.
	add		eax, [ebp-8] ; eax reg + y 
	jo		errorMsg ; if overflow flag is set, number is too large to fit in 32 bit register, re-prompt user.
	mov		[ebp-4], eax ; x = 10*x +(str[k]-48)
	loop	L3

	; take 2's complement of the converted integer
	neg		eax
	jmp		validInt

	; if we get an invalid value, display error message, repeat loop without decrementing counter or saving the value.
errorMsg:
	call	Crlf
	mov		edx, [ebp + 16] ;@error1
	call	WriteString
	call	Crlf
	jmp		redo 

validInt:
	;restore registers, return
	pop		edi
	pop		esi
	pop		edx
	pop		ecx
	pop		ebx
	mov		esp, ebp ; remomve local variables from stack
	pop		ebp
	ret		16
readVal		ENDP

;Procedure to convert integer value to character string and display as string.
;receives: offset of list_sum / list_avg, offset of string3 / string6, offset of sum_label / avg_label, offset of string4 / string7 (all depending on which call)
;offset of minus_label.
;returns: integer converted to string and displayed using displayString macro.
;preconditions:  integer values for list_sum / list_avg must be pre-calculated
;registers changed: eax, ebx, ecx, edx, esi, edi
writeVal	PROC
	;initialize stack frame, save register values.
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	;initialize array and label for printing. Check whether value is positive or negative.
	mov		eax, [ebp + 8] ; value of list_sum / list_avg
	mov		edi, [ebp + 12] ; @string3
	mov		edx, [ebp + 16] ; @sum_label / @avg_label
	call	CrLf
	call	WriteString
	cmp		eax, 0
	jl		negateVal
	jmp		posVal

	;if the value is negative, take the 2's complement, print "-", convert positive integer
negateVal:
	neg		eax
	mov		edx, [ebp + 24] ; @minus_label
	call	WriteString

posVal:
	cld ; Direction = fwd
	
L4:
	; algorithm to convert integer value in list_sum / list_avg to string. 
	; concept learned from https://www.quora.com/What-is-the-method-of-converting-the-decimal-number-to-ASCII-code 
	; and https://stackoverflow.com/questions/29065108/masm-integer-to-string-using-std-and-stosb. 
	mov		ebx, 10
	cdq
	idiv	ebx ; divide integer value by 10

	add		edx, 48 ; remainder + 48 = ascii character value
	
	push	eax ; save current value of eax for potential use in next iteration
	mov		eax, edx ; ascii character value moved to eax and saved to string with stosb
	stosb  
	pop		eax ; value of eax restored
	cmp		eax, 0 ; if quotient value is 0, we've reached the end. Otherwise, the quotient is used in the next iteration of the algorithm
	je		newIntLoop
	jmp		L4

newIntLoop:
	;reverse string. (learned from demo6.asm)
	push	[ebp + 12] ; @string3 / @string6
	call	Strlen
	mov		ecx, eax ; eax now contains the length of string3. Use to initialize counter.
	mov		esi, [ebp + 12] ; @string3 / @string6
	add		esi, ecx
	dec		esi ; start at the end of the source string
	mov		edi, [ebp + 20] ; @string4 / @string7
	
	; takes last element from source array and places it as first element in destination array
reverse:
	std
	lodsb
	cld
	stosb
	loop	reverse
	
	;string is now in the correct order. Invoke displayString macro.
	displayString [ebp + 20]; @string4 / @string7, depending on which call to WriteVal.
	call	CrLf

	; restore registers, return
	pop		edi
	pop		esi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp

	ret		20
writeVal	ENDP

;Procedure to display the contents of the user's string input in numeric form.
;receives: offset of string5, offset of spacer, offset of list_label1.
;returns: prints the contents of the list to the console.
;preconditions:  string5 must have been loaded with integer values using readVal prcedure.
;registers changed: eax, ecx, edx, esi
displayList	PROC
	push	ebp
	mov		ebp, esp
	push	eax
	push	ecx
	push	edx
	push	esi

	; print list_label1, initialize array string5 for printing
	call	CrLf
	mov		edx, [ebp + 16] ; @list_label1
	mov		ecx, 10
	call	WriteString
	call	CrLf
	mov		edx, [ebp + 12] ; @spacer
	mov		esi, [ebp + 8] ; @string5

	; print integer array 
displayIntArray:
	mov		eax, [esi] 
	call	WriteInt
	add		esi, 4
	call	WriteString 
	loop	displayIntArray
	call	CrLf

	;restore registers, return
	pop		esi
	pop		edx
	pop		ecx
	pop		eax
	pop		ebp
	ret		12
displayList	ENDP


;Procedure to calculate values for the sum and average of the integer array and save them into variables list_sum and list_avg
;receives: offset of string5, and offsets of variables list_sum and list_avg
;returns: sum and average of integer array are stored in variables list_sum and List_avg
;preconditions:  string5 must have been loaded with integer values using readVal prcedure.
;registers changed: eax, ebx, ecx, edx, esi
sumAndAverage	PROC
	; intialize stack frame, save registers
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi

	; initialize int array, initialize accumulator, initialize counter, initialize OFFSET for variable list_sum
	mov		esi, [ebp + 8] ; @string5
	mov		eax, 0 
	mov		ebx, [ebp + 12] ; @list_sum
	mov		ecx, 10

	; Calculate sum of integer list, save to variable list_sum
sumLoop:
	add		eax, [esi]
	add		esi, 4
	loop	sumLoop
	mov		[ebx], eax ; list_sum now contains the sum the integer list

	; Calculate the average, save to variable list_avg
	mov		ebx, [ebp + 16] ; @list_avg
	push	ebx
	mov		ebx, 10
	cdq
	idiv	ebx
	pop		ebx
	mov		[ebx], eax ; list_avg now contains the average of the list, rounded down to the nearest integer

	;Restore registers, return
	pop		esi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		12
sumAndAverage	ENDP

;Sub-procedure to calculate length of string for use as loop counter in WriteVal procedure.
;receives: offset of string3, (string of characters converted from integer value of list_sum / list_avg, depending on which call).
;returns: length of string in eax register.
;preconditions: string3 must be preloaded with ascii values from integer value of list_sum / list_avg.
;registers changed: eax, edi
; Note: Concept learned from Textbook p. 389.
Strlen		PROC USES edi,
	pstring: PTR BYTE
	mov		edi, pString	
	mov		eax, 0

Lp1:
	cmp		BYTE PTR[edi],0 ; if the byte is empty, return to calling procedure
	je		Lp2
	inc		edi
	inc		eax ; eax incremented for each character value in the string
	jmp		Lp1
Lp2:
	ret
Strlen		ENDP

;Procedure to close out the program.
;receives: offset of goodbye string
;returns: none
;preconditions:  none
;registers changed: edx
farewell	PROC
	push	ebp
	mov		ebp, esp
	push	edx

	call	CrLf
	mov		edx, [ebp + 8] ; @goodbye
	call	WriteString
	call	CrLf

	pop		edx
	pop		ebp
	ret 4
farewell	ENDP



END main
