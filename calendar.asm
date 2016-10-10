assume cs:cseg,ds:cseg
cseg segment
org 100h
start:
	jmp main
	year dw 0
	month db 0
	monthDays db 31,28,31,30,31,30,31,31,30,31,30,31
	leap db 0
	jan1 db 0
	scr dw 80*25 dup(?)
	monthNames db "JanFebMarAprMayJunJulAugSepOctNovDec"
	dayNames db "SunMonTueWedThuFriSat"
	tmp db 0

saveClrScreen:
	mov ax,0B800h
	mov es,ax
	mov cx,80*25
	sub si,si
	sCS:
	mov ax,es:[si]
	mov es:[si],0F20h
	mov scr[si],ax
	add si,2
	loop sCS
	ret
	
rtnScreen:
	mov ax,0B800h
	mov es,ax
	mov cx, 80*25
	sub si,si
	rS:
	mov ax,scr[si]
	mov es:[si],ax
	add si,2
	loop rS
	ret
	
clrScreen:
	mov ax,0B800h
	mov es,ax
	mov cx, 80*25
	mov si,80
	cS1:
	mov es:[si],0F20h
	add si,2
	loop cS1
	ret
	
shrinkCursor:
	mov ch,32
	mov ah,1
	int 10h
	ret
	
restoreCursor:
	mov ch,6
	mov cl,7
	mov ah,1
	int 10h
	ret
	
getDate:
	mov ah,2Ah
	int 21h
	mov year,cx
	dec dh
	mov month,dh
	ret

calcJan1:
	sub dx,dx
	mov ax,year
	dec ax
	push ax
	push ax
	mov bx,4
	div bx
	mov ax,dx
	mov bx,5
	mul bx
	mov cx,ax
	pop ax
	mov bx,100
	div bx
	mov ax,dx
	mov bx,4
	mul bx
	add cx,ax
	pop ax
	mov bx,400
	div bx
	mov ax,dx
	mov bx,6
	mul bx
	add cx,ax
	inc cx
	mov bx,7
	mov ax,cx
	div bx
	mov jan1,dl
	
	mov ax,year
	mov bx,4
	sub dx,dx
	div bx
	cmp dx,0
	jnz notLeapYear
	
	mov ax,year
	mov bx,100
	sub dx,dx
	div bx
	cmp dx,0
	jnz leapYear
	
	mov ax,year
	mov bx,400
	sub dx,dx
	div bx
	cmp dx,0
	jz leapYear	
	
	notLeapYear:
	mov leap,0
	ret
	leapYear:
	mov leap,1
	ret	

drawTitle:
	mov al,month
	mov cl,3
	mul cl
	sub ah,ah
	mov bx,ax	
	mov al,monthNames[bx]
	mov ah,0Fh
	mov es:[76],ax
	inc bx	
	mov al,monthNames[bx]
	mov ah,0Fh
	mov es:[78],ax
	inc bx	
	mov al,monthNames[bx]
	mov ah,0Fh
	mov es:[80],ax
	inc bx
	call drawYear
	ret
	
drawYear:
	mov ax,year
	mov bx,10
	sub dx,dx	
	div bx
	add dx,'0'
	mov es:[8],dl
	sub dx,dx
	div bx
	add dx,'0'
	mov es:[6],dl
	sub dx,dx	
	div bx
	add dx,'0'
	mov es:[4],dl
	sub dx,dx	
	div bx
	add dx,'0'
	mov es:[2],dl
	sub dx,dx	
	ret
	
drawVertLines:
	push cx
	mov cx,8
	dC1:
	mov ax,0Fb3h
	mov es:[si],ax
	add si,22
	loop dC1
	sub si,16
	pop cx
	ret

drawHorzLineSeg:
	push cx
	mov cx,10
	dHLS:
	mov ax,0FC4h
	add si,2
	mov es:[si],ax
	loop dHLS
	add si,2
	pop cx
	ret

drawHorzLines:
	push cx
	mov cx,7
	mov ax,0FC3h
	mov es:[si],ax
	dHL1:
	call drawHorzLineSeg
	mov ax,0FC5h
	mov es:[si],ax
	loop dHL1
	mov ax,0FB4h
	mov es:[si],ax
	add si,6
	pop cx
	ret
	
drawBottomLines:
	push cx
	mov cx,7
	mov ax,0FC0h
	mov es:[si],ax
	dBL1:
	call drawHorzLineSeg
	mov ax,0FC1h
	mov es:[si],ax
	loop dBL1
	mov ax,0FD9h
	mov es:[si],ax
	add si,10
	mov ax,0F1Bh
	mov es:[si],ax
	mov ax,0F1Ah
	add si,146
	mov es:[si],ax
	pop cx
	ret
	
drawFrame:
	mov si,160
	call drawVertLines
	mov cx,6
	dF1:
	call drawHorzLines
	call drawVertLines
	call drawVertLines
	loop dF1
	call drawBottomLines
	ret	
	
drawDays:
	mov cx,7
	mov si,170
	sub bx,bx
	mov ah,0Fh
	dD1:
	mov al,dayNames[bx]
	mov es:[si],ax
	add si,2
	inc bx	
	mov al,dayNames[bx]
	mov es:[si],ax	
	add si,2
	inc bx
	mov al,dayNames[bx]
	mov es:[si],ax
	add si,18
	inc bx
	loop dD1
	ret

firstOfMonth:
	sub ax,ax
	sub bx,bx
	sub cx,cx
	sub dx,dx
	mov cl,month
	cmp cl,0
	jz fOM0
	fOM1:
	dec cl
	cmp cl,1
	jnz fOM2
	push bx
	sub bh,bh
	mov bl,leap
	add ax,bx
	pop bx
	fOM2:
	mov bl,cl
	mov dl,monthDays[bx]
	add ax,dx
	or cl,cl
	jnz fOM1
	sub dh,dh
	mov dl,jan1
	add ax,dx
	mov bx,7
	sub dx,dx
	div bx
	ret
	fOM0:
	mov dl,jan1
	ret
	
writeNum:
	.186
	pusha
	mov ax,cx
	mov bx,10
	div bx
	add dx,'0'
	mov dh,0Fh
	push dx
	sub dx,dx
	div bx
	add dx,'0'
	mov dh,0Fh
	mov es:[si],dx
	pop dx
	add si,2
	mov es:[si],dx
	popa
	ret
	
drawNumbers:
	call firstOfMonth		
	pusha
	sub bh,bh
	mov bl,month
	sub ah,ah
	mov al,monthDays[bx]
	mov bl,month
	cmp bl,1
	jnz sBM
	add al,leap
	sBM:
	mov tmp,al
	popa
	mov bl,tmp
	mov cx,0
	mov si,482
	mov ax,22
	mul dx
	add si,ax	
	dN1:
	inc cx
	call writeNum
	add si,22
	cmp si,636
	jz dN2
	cmp si,1116
	jz dN2
	cmp si,1596
	jz dN2
	cmp si,2076
	jz dN2
	cmp si,2556
	jz dN2
	jmp dN3
	dN2:
	add si,326
	dN3:
	cmp cx,bx
	jnz dN1

	ret
	
draw:
	mov ax,0b800h
	mov es,ax
	sub si,si
	call drawTitle
	call drawDays
	call drawFrame
	call drawNumbers
	ret
	
waitForStroke:
	mov ah,10h
	int 16h
	cmp al,1Bh
	jz wFS1
	
	cmp ah,4Bh
	jnz wFS2
	mov al,month
	cmp al,0
	jnz wFS3
	mov bx,year
	dec bx
	mov year,bx
	mov month,11
	jmp wFS5
	wFS3:
	dec al
	mov month,al
	jmp wFS5	
	
	wFS2:
	cmp ah,4Dh
	jnz wFS1
	mov al,month
	cmp al,11
	jnz wFS4
	mov bx,year
	inc bx
	mov year,bx
	mov month,0
	jmp wFS5
	wFS4:
	inc al
	mov month,al
	jmp wFS5
	
	wFS5:
	call clrScreen
	jmp mainRestart
	wFS1:
	ret
	
main:
	call saveClrScreen
	call shrinkCursor
	call getDate
	mainRestart:
	call calcJan1	
	call draw
	call waitForStroke
	call restoreCursor
	call rtnScreen
	int 20h
cseg ends
end start