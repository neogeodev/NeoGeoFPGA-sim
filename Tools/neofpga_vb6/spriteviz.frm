VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Spriteviz"
   ClientHeight    =   4440
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   12510
   Icon            =   "spriteviz.frx":0000
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   ScaleHeight     =   296
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   834
   StartUpPosition =   2  'CenterScreen
   Begin VB.ListBox List2 
      BeginProperty Font 
         Name            =   "Bitstream Vera Sans Mono"
         Size            =   9
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3840
      ItemData        =   "spriteviz.frx":000C
      Left            =   10440
      List            =   "spriteviz.frx":000E
      TabIndex        =   2
      Top             =   240
      Width           =   1815
   End
   Begin VB.PictureBox Picture1 
      AutoRedraw      =   -1  'True
      BackColor       =   &H00000000&
      BorderStyle     =   0  'None
      Height          =   3960
      Left            =   240
      ScaleHeight     =   264
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   384
      TabIndex        =   1
      Top             =   240
      Width           =   5760
   End
   Begin VB.ListBox List1 
      BeginProperty Font 
         Name            =   "Bitstream Vera Sans Mono"
         Size            =   9
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3840
      ItemData        =   "spriteviz.frx":0010
      Left            =   6240
      List            =   "spriteviz.frx":0012
      TabIndex        =   0
      Top             =   240
      Width           =   3975
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Type Sprite
    n As Integer
    X As Integer
    Y As Integer
    h As Integer
    zh As Integer
    TileMap(64) As String
End Type

Dim VRAMSlow(65536) As Integer
Dim VRAMFast(3072) As Integer
Dim Sprites(384) As Sprite

Private Sub Form_Load()
    Dim c, d, i As Integer
    Dim ShrinkVal As Integer
    Dim h As Integer
    Dim XPos As Integer
    Dim YPos As Integer
    Dim ZStr As String
    Dim ChStr As String
    Dim TMWordEven, TMWordOdd As Single
    Dim TileNumber As Single
    Dim PaletteNumber As Integer
    Dim Attributes As Integer
    Dim fso As FileSystemObject
    
    Set fso = New FileSystemObject
    
    If fso.FileExists("vram_slow.bin") = False Or fso.FileExists("vram_fast.bin") = False Then
        MsgBox "Missing .bin files !", vbCritical
        End
    End If

    Open "vram_slow.bin" For Binary As #1
        Get #1, , VRAMSlow
    Close #1
    Open "vram_fast.bin" For Binary As #1
        Get #1, , VRAMFast
    Close #1
    
    ' Parse sprites
    i = 0
    For c = 0 To 384 - 1
        ShrinkVal = VRAMFast(c) And &HFFF
        XPos = ((VRAMFast(&H400 + c) \ 2) And &H7FFF) \ 64
        YPos = 503 - (((VRAMFast(&H200 + c) \ 2) And &H7FFF) \ 64)
        
        If (VRAMFast(&H400 + c) And &H40) = &H40 Then
            ChStr = "CH"
        Else
            ChStr = ""
        End If
        
        h = VRAMFast(&H200 + c) And 63
        
        If ShrinkVal = &HFFF Then
            ZStr = "Max"
        Else
            ZStr = Pad(Hex(ShrinkVal), 4, "0")
        End If
        
        If h > 0 Then
            With Sprites(i)
                .n = c
                .X = XPos
                .Y = YPos
                .h = h
                .zh = ShrinkVal \ 256
            End With
            
            ' Parse tilemap
            For d = 0 To 64 - 1
                TMWordEven = CSng(VRAMSlow(((c * 32) + d) * 2))
                TMWordEven = TMWordEven And 65535#
                TMWordOdd = CSng(VRAMSlow(((c * 32) + d) * 2 + 1))
                TMWordOdd = TMWordOdd And 65535#
                
                TileNumber = TMWordEven + (((TMWordOdd \ 16) And 15) * 65536#)
                PaletteNumber = TMWordOdd \ 256
                Attributes = TMWordOdd And 15
                
                Sprites(i).TileMap(d) = Pad(Hex(TileNumber), 4, "0") & " " & Pad(Hex(PaletteNumber), 2, "0") & " " & Hex(Attributes)
            Next d
            
            List1.AddItem Pad(Hex(c), 3, " ") & ": X=" & Pad(XPos, 4, " ") & _
                            "  Y=" & Pad(YPos, 4, " ") & _
                            "  Z=" & ZStr & _
                            "  H=" & Pad(h, 2, " ") & _
                            ChStr
            
            i = i + 1
        End If
        
    Next c
    
    Redraw
End Sub

Private Sub Redraw()
    Dim i As Integer
    Dim Sel As Integer
    
    Picture1.Cls
    Picture1.Picture = LoadPicture("screen.bmp")
    Picture1.PaintPicture Picture1.Picture, 0, 8, 320, 224, 0, 0, 320, 224
    Picture1.Line (0, 0)-(320, 8), vbBlack, BF
    
    Sel = List1.ListIndex
    If Sel < 0 Then Sel = 0
    i = 0
    
    Do
        If Sprites(i).h = 0 Then Exit Do
        
        DrawSprite Sprites(i).X, Sprites(i).Y, Sprites(i).zh, Sprites(i).h * 16, RGB(255, 63, 63)
        
        i = i + 1
    Loop
    
    ' Highlight selected sprite or tile
    If List2.ListIndex < 0 Then
        DrawSprite Sprites(Sel).X, Sprites(Sel).Y, Sprites(Sel).zh, Sprites(Sel).h * 16, vbWhite
    Else
        DrawSprite Sprites(Sel).X, Sprites(Sel).Y + (List2.ListIndex * 16), Sprites(Sel).zh, 16, vbWhite
    End If
    
    ' Mark active area
    Picture1.Line (0, 8)-(320 - 1, 224 + 8 - 1), vbGreen, B
End Sub

Private Sub DrawSprite(ByVal X As Integer, ByVal Y As Integer, ByVal w As Integer, ByVal h As Integer, ByVal col As Single)
    Dim bot As Integer
    
    bot = Y + h
    
    Picture1.Line (X, Y)-(X + w, bot), col, B
    
    If bot > 511 Then
        ' Wrap
        Picture1.Line (X, 0)-(X + w, bot - 512), col, B
    End If
End Sub

Private Function Pad(ByVal s As String, ByVal Length As Integer, ByVal p As String) As String
    Pad = s
    Do While Len(Pad) < Length
        Pad = p & Pad
    Loop
End Function

Private Sub List1_Click()
    Dim d As Integer
    List2.Clear
    
    For d = 0 To Sprites(List1.ListIndex).h - 1
        List2.AddItem Sprites(List1.ListIndex).TileMap(d)
    Next d
    
    Redraw
End Sub

Private Sub List2_Click()
    Redraw
End Sub

Private Sub Picture1_MouseMove(Button As Integer, Shift As Integer, X As Single, Y As Single)
    Form1.Caption = Hex(&H100 + Y)
End Sub
