FasdUAS 1.101.10   ��   ��    k             l      ��  ��   ��
This is hacky application wrapper to launch a script from a relative path. 
The EMLbootstrap script will install this script as a automatic login item. 

This will in turn launch a script which displays the text file in a dialog.
I did this way for the following reason:
1. We never have to change this application and re-export: We just make changes to the text file and/or script this application calls.
2. This application has a special field in the info.plist that makes it not appear in the dock on launch. We don't want to change that every time.
3. Git and distribution. This will be installed from a git repository, so it's better to change the text file or script, rather than a 'compiled' applescript application.
     � 	 	� 
 T h i s   i s   h a c k y   a p p l i c a t i o n   w r a p p e r   t o   l a u n c h   a   s c r i p t   f r o m   a   r e l a t i v e   p a t h .   
 T h e   E M L b o o t s t r a p   s c r i p t   w i l l   i n s t a l l   t h i s   s c r i p t   a s   a   a u t o m a t i c   l o g i n   i t e m .   
 
 T h i s   w i l l   i n   t u r n   l a u n c h   a   s c r i p t   w h i c h   d i s p l a y s   t h e   t e x t   f i l e   i n   a   d i a l o g . 
 I   d i d   t h i s   w a y   f o r   t h e   f o l l o w i n g   r e a s o n : 
 1 .   W e   n e v e r   h a v e   t o   c h a n g e   t h i s   a p p l i c a t i o n   a n d   r e - e x p o r t :   W e   j u s t   m a k e   c h a n g e s   t o   t h e   t e x t   f i l e   a n d / o r   s c r i p t   t h i s   a p p l i c a t i o n   c a l l s . 
 2 .   T h i s   a p p l i c a t i o n   h a s   a   s p e c i a l   f i e l d   i n   t h e   i n f o . p l i s t   t h a t   m a k e s   i t   n o t   a p p e a r   i n   t h e   d o c k   o n   l a u n c h .   W e   d o n ' t   w a n t   t o   c h a n g e   t h a t   e v e r y   t i m e . 
 3 .   G i t   a n d   d i s t r i b u t i o n .   T h i s   w i l l   b e   i n s t a l l e d   f r o m   a   g i t   r e p o s i t o r y ,   s o   i t ' s   b e t t e r   t o   c h a n g e   t h e   t e x t   f i l e   o r   s c r i p t ,   r a t h e r   t h a n   a   ' c o m p i l e d '   a p p l e s c r i p t   a p p l i c a t i o n . 
   
  
 l     ��  ��    / )hack to do relative paths in applescript.     �   R h a c k   t o   d o   r e l a t i v e   p a t h s   i n   a p p l e s c r i p t .      l     ����  r         l     ����  I    �� ��
�� .earsffdralis        afdr   f     ��  ��  ��    o      ���� 0 running_path  ��  ��        l    ����  O        k           l   ��  ��    5 /set the path to text so that we can concatenate     �     ^ s e t   t h e   p a t h   t o   t e x t   s o   t h a t   w e   c a n   c o n c a t e n a t e   !�� ! r     " # " c     $ % $ n     & ' & m    ��
�� 
ctnr ' o    ���� 0 running_path   % m    ��
�� 
ctxt # o      ���� 0 parent_path  ��    m    	 ( (�                                                                                  MACS  alis    t  Macintosh HD               ʵF�H+   w�,
Finder.app                                                      y�:�_��        ����  	                CoreServices    ʵ�      �`D     w�, w�) w�(  6Macintosh HD:System: Library: CoreServices: Finder.app   
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��  ��  ��     ) * ) l     �� + ,��   + V Pnow that we have the full relative path, convert to alias so that we can launch.    , � - - � n o w   t h a t   w e   h a v e   t h e   f u l l   r e l a t i v e   p a t h ,   c o n v e r t   t o   a l i a s   s o   t h a t   w e   c a n   l a u n c h . *  . / . l    0���� 0 r     1 2 1 c     3 4 3 b     5 6 5 o    ���� 0 parent_path   6 m     7 7 � 8 8  u s e a g e . s c p t 4 m    ��
�� 
alis 2 o      ���� 0 script_path  ��  ��   /  9 : 9 l     �� ; <��   ;  now we can run it    < � = = " n o w   w e   c a n   r u n   i t :  >�� > l   " ?���� ? I   "�� @��
�� .sysodsct****        scpt @ o    ���� 0 script_path  ��  ��  ��  ��       �� A B��   A ��
�� .aevtoappnull  �   � **** B �� C���� D E��
�� .aevtoappnull  �   � **** C k     " F F   G G   H H  . I I  >����  ��  ��   D   E 
���� (������ 7������
�� .earsffdralis        afdr�� 0 running_path  
�� 
ctnr
�� 
ctxt�� 0 parent_path  
�� 
alis�� 0 script_path  
�� .sysodsct****        scpt�� #)j  E�O� 	��,�&E�UO��%�&E�O�j 	 ascr  ��ޭ