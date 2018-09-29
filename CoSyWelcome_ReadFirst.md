
* * *

<div style="margin-left: 40px;"> Welcome ,  

<div style="text-align: center;"><big><big><small>You are an</small> <span style="font-weight: bold; font-style: italic;">α</span></big> among <big><span style="font-weight: bold; font-style: italic;">α</span></big>s seeking <big><span style="font-weight: bold; font-style: italic;">α</span> </big>. </big>  
</div>

I'm sure you know a lot more about lots of areas of computer usage than I do . **<font><big>[**<font color="#cc00cc"><font face="Comic
                                    Sans MS">_CoSy_</font></font>**](http://cosy.com/)</big></font>** is my escape from having to deal with a lot of that jumble .  

<span style="font-weight: bold;">The central issue of concern</span> is that the 2007 version of [<span style="font-weight: bold;">Reva</span> Forth](http://dev.ronware.org/p/reva/) <small>**<font><big>[**<font color="#cc00cc"><font face="Comic
                                    Sans MS">_CoSy_</font></font>**](http://cosy.com/)</big></font>**</small> is currently built in causes false positives on some malware programs . I just upgraded to <span style="font-style: italic;">Windows 10</span> and <span style="font-style: italic;">Windows Defender</span> now seems to see `?:\4thCoSy\bin\reva.exe` as malware .  

I think the best procedure is to go to <span style="font-style: italic;">Windows Defender</span> in the <span style="font-style: italic;">Control Panel</span> , choose <span style="font-style: italic;">Settings</span> in the upper right , then scroll down to <span style="font-style: italic;">Add an exclusion</span> and <span style="font-style: italic;">Exclude the folder </span> `J:\4thCoSy` <span style="font-style: italic;"></span>or whatever the drive letter may be before anything else .  This is an area you may understand how to deal with better than I do . It looks like the main documentation for <span style="font-style: italic;">Defender</span> is at [http://www.tenforums.com/tutorials/5924-windows-defender-exclusions-add-remove-windows-10-a.html](http://www.tenforums.com/tutorials/5924-windows-defender-exclusions-add-remove-windows-10-a.html)  

See [http://cosy.com/CoSy/4thCoSy/y16/WindowsDefenderExclusion.html](http://cosy.com/CoSy/4thCoSy/y16/WindowsDefenderExclusion.html) for screenshots of the procedure .  

I have included a `.zip` which I believe are never normally examined in any case .  

I have also included a `.zip` of the "final" version of [<span style="font-weight: bold;">Reva</span>](http://dev.ronware.org/p/reva/) , 201101 . I have never seen any indication that it has false alarm problems . That's a motivation to move forward to that release and I'll bring anybody up to date on the issues I ran into .  

<span style="font-weight: bold;">The  IUP GUI will bomb</span> if the window size is altered after being written into . There are other apparently GUI related bombs which have been lower priority than getting the <span style="font-style: italic;">kernel</span> correct . But , that's just another reason to understand that `control-s` is your best friend . That's some of the oldest and necessarily reliable vocabulary .  

The IUP interface also needs to be updated or replaced , too .  But those discussions are down the road .  

Those are the 2 issues I think are critical . To riff on an illustrious fellow memeber of my lastname-_[granfalloon](https://en.wikipedia.org/wiki/Granfalloon "Granfalloon")_ , these are a couple of small tasks for a language community , large for one man .  

Awaiting your first response .  

Bob A  

* * *
