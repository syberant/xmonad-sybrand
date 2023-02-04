-- Switch between different sets of workspaces assigned to specific projects.
--
-- Plan:
--   Always have a default '' project as fallback
--   Get every project their own workspaces 7-9
--   Use an XMonad Prompt and picker to switch between projects and create new ones
--   Delete a project if no open windows?
--
-- TODO:
--   Remove `Project` type, it does not serve any purpose
--   General cleanup
--
-- Links:
-- https://hackage.haskell.org/package/xmonad-contrib-0.17.1/docs/XMonad-Actions-DynamicWorkspaces.html
-- https://hackage.haskell.org/package/xmonad-contrib-0.17.1/docs/XMonad-Util-ExtensibleState.html
-- https://www.reddit.com/r/xmonad/comments/fgyzc/xmonadactionsdynamicworkspaces_where_have_you/

module Projects (hiddenWorkspaces, switchProject, addProject, removeCurrentProject, withNthFilteredWorkspace) where

import           Control.Monad                    (mapM_)
import qualified Data.List                        as List
import qualified Data.Map.Strict                  as Map
import           XMonad                           hiding (workspaces)
import           XMonad.Actions.DynamicWorkspaces (addHiddenWorkspaceAt,
                                                   removeWorkspaceByTag)
import           XMonad.Prompt                    (XPConfig,
                                                   mkComplFunFromList',
                                                   mkXPrompt)
import           XMonad.Prompt.Workspace          (Wor (Wor))
import           XMonad.StackSet                  (greedyView, tag, workspaces)
import qualified XMonad.Util.ExtensibleState      as XS
import           XMonad.Util.WorkspaceCompare     (getSortByIndex)


data State = State
    { activeProjectName :: String
    , projects          :: Map.Map String Project
    } deriving (Read, Show)
instance ExtensionClass State where
    initialValue = State defaultProject $ Map.singleton defaultProject (Project defaultProject 3)
    extensionType = PersistentExtension

activeProject (State active projs) = projs Map.! active

hiddenWorkspaces :: X [String]
hiddenWorkspaces = do
    (State active projects) <- XS.get
    return $ ["NSP"] ++ (concat $ map projectTags $ Map.elems $ Map.delete active projects)

-- Modified from: https://hackage.haskell.org/package/xmonad-contrib-0.17.1/docs/src/XMonad.Actions.DynamicWorkspaces.html#withNthWorkspace
withNthFilteredWorkspace :: (String -> WindowSet -> WindowSet) -> Int -> X ()
withNthFilteredWorkspace job wnum = do
    hidden <- hiddenWorkspaces
    s <- getSortByIndex
    ws <- gets (map tag . s . workspaces . windowset)
    case drop wnum (ws List.\\ hidden) of
        (w:_) -> windows $ job w
        []    -> return ()

data Project = Project
    { name   :: String
    , number :: Int
    } deriving (Read, Show)

defaultProject = ""
projectTags (Project name n) = map (\x -> name ++ show x) $ map (6+) [1..n]

switchProject :: XPConfig -> X ()
switchProject conf = do
        (State _ projs) <- XS.get
        mkXPrompt (Wor "Project name: ") conf (mkComplFunFromList' conf $ Map.keys projs) switchOrAdd
    where
        -- compl = const (return [])
        switchOrAdd name = do
                (State _ projs) <- XS.get
                if Map.member name projs then return () else addProject name
                (State _ projs) <- XS.get
                XS.put (State name projs)
                windows (greedyView $ name ++ "8")


addProject :: String -> X ()
addProject name = do
        XS.modify changeState
        mapM_ appendWorkspace $ projectTags proj
    where
        proj = Project name 3
        changeState (State act projs) = State act $ Map.insert name proj projs
        appendWorkspace = addHiddenWorkspaceAt (\x xs -> x:xs)

removeCurrentProject :: X ()
removeCurrentProject = do
    (State active _) <- XS.get
    if active == defaultProject then return () else removeProject active

removeProject :: String -> X ()
removeProject name = do
        state <- XS.get
        delWorkspaces (activeProject state)
        if activeProjectName state == name then windows (greedyView $ defaultProject ++ "1") else return ()
        XS.put (changeState state)
    where
        changeState (State act projs)
            | act == name = State defaultProject (Map.delete name projs)
            | otherwise = State act (Map.delete name projs)
        delWorkspaces proj = mapM_ removeWorkspaceByTag (projectTags proj)
