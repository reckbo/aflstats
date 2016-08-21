import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util
import Development.Shake.Config
 

{-Functions-}
inoutdir x = "_data" </> x
takeBaseName2 x = dropExtension $ takeBaseName x

{-Pipeline-}
main :: IO ()
main = shakeArgs shakeOptions{shakeFiles="_data"} $ do
    usingConfigFile "build.cfg"

    action $ do
        Just xs <- getConfig "years"
        let matches = [ inoutdir x <.> "matches.txt" | x <- words xs ]
        let matchpages = [ inoutdir x <.> "matchpages" | x <- words xs ]
        need (matches ++ matchpages)

    "//*.matches.html" %> \out -> do
        let year = takeBaseName2 out
        cmd ("curl http://afltables.com/afl/seas/" ++ year ++ ".html") "-o" out

    "//*.matches.txt" %> \out -> do
        let html = out -<.> "html"
        need [html]
        Stdout txt <- cmd "w3m -dump -cols 150 -T text/html" html 
        writeFile' out txt

    "//*.matchpages" %> \out -> do
        let year = takeBaseName out
        let html = year <.> "matches.html"
        need [html]
        () <- cmd "mkdir" out
        Stdout stdout <- cmd Shell "grep" "Match stats" html "|" "grep -oE" "'[[:digit:]]+.html'"
        mapM_ (\stathtml -> cmd ("curl http://afltables.com/afl/stats/games/"++year++"/"++stathtml) "-o" (out </> stathtml)) (lines stdout)

        {-let statpage = (head $ lines stdout)-}
        {-cmd ("curl http://afltables.com/afl/stats/games/"++year++"/"++statpage) "-o" (out </> statpage)-}

