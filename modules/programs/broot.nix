{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.broot;

  tomlFormat = pkgs.formats.toml { };

  brootConf = {
    verbs = cfg.verbs;
    skin = cfg.skin;
    modal = cfg.modal;
  };

in {
  meta.maintainers = [ hm.maintainers.aheaume ];

  options.programs.broot = {
    enable = mkEnableOption "Broot, a better way to navigate directories";

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Fish integration.
      '';
    };

    modal = mkEnableOption "modal (vim) mode";

    verbs = mkOption {
      type = with types; listOf (attrsOf (either bool str));
      default = [
        {
          invocation = "p";
          execution = ":parent";
        }
        {
          invocation = "edit";
          shortcut = "e";
          execution = "$EDITOR {file}";
        }
        {
          invocation = "create {subpath}";
          execution = "$EDITOR {directory}/{subpath}";
        }
        {
          invocation = "view";
          execution = "less {file}";
        }
      ];
      example = literalExpression ''
        [
          { invocation = "p"; execution = ":parent"; }
          { invocation = "edit"; shortcut = "e"; execution = "$EDITOR {file}" ; }
          { invocation = "create {subpath}"; execution = "$EDITOR {directory}/{subpath}"; }
          { invocation = "view"; execution = "less {file}"; }
          {
            invocation = "blop {name}\\.{type}";
            execution = "/bin/mkdir {parent}/{type} && /usr/bin/nvim {parent}/{type}/{name}.{type}";
            from_shell = true;
          }
        ]
      '';
      description = ''
        Define new verbs. For more information, see
        <link xlink:href="https://dystroy.org/broot/documentation/configuration/#verb-definition-attributes"/>.
        </para><para>
        The possible attributes are:
        </para>

        <para>
        <variablelist>
          <varlistentry>
            <term><literal>invocation</literal> (optional)</term>
            <listitem><para>how the verb is called by the user, with placeholders for arguments</para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>execution</literal> (mandatory)</term>
            <listitem><para>how the verb is executed</para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>key</literal> (optional)</term>
            <listitem><para>a keyboard key triggering execution</para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>shortcut</literal> (optional)</term>
            <listitem><para>an alternate way to call the verb (without
            the arguments part)</para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>leave_broot</literal> (optional)</term>
            <listitem><para>whether to quit broot on execution
            (default: <literal>true</literal>)</para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>from_shell</literal> (optional)</term>
            <listitem><para>whether the verb must be executed from the
            parent shell (default:
            <literal>false</literal>)</para></listitem>
          </varlistentry>
        </variablelist>
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.broot;
      defaultText = literalExpression "pkgs.broot";
      description = "Package providing broot";
    };

    skin = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          status_normal_fg = "grayscale(18)";
          status_normal_bg = "grayscale(3)";
          status_error_fg = "red";
          status_error_bg = "yellow";
          tree_fg = "red";
          selected_line_bg = "grayscale(7)";
          permissions_fg = "grayscale(12)";
          size_bar_full_bg = "red";
          size_bar_void_bg = "black";
          directory_fg = "lightyellow";
          input_fg = "cyan";
          flag_value_fg = "lightyellow";
          table_border_fg = "red";
          code_fg = "lightyellow";
        }
      '';
      description = ''
        Color configuration.
        </para><para>
        Complete list of keys (expected to change before the v1 of broot):

        <itemizedlist>
          <listitem><para><literal>char_match</literal></para></listitem>
          <listitem><para><literal>code</literal></para></listitem>
          <listitem><para><literal>directory</literal></para></listitem>
          <listitem><para><literal>exe</literal></para></listitem>
          <listitem><para><literal>file</literal></para></listitem>
          <listitem><para><literal>file_error</literal></para></listitem>
          <listitem><para><literal>flag_label</literal></para></listitem>
          <listitem><para><literal>flag_value</literal></para></listitem>
          <listitem><para><literal>input</literal></para></listitem>
          <listitem><para><literal>link</literal></para></listitem>
          <listitem><para><literal>permissions</literal></para></listitem>
          <listitem><para><literal>selected_line</literal></para></listitem>
          <listitem><para><literal>size_bar_full</literal></para></listitem>
          <listitem><para><literal>size_bar_void</literal></para></listitem>
          <listitem><para><literal>size_text</literal></para></listitem>
          <listitem><para><literal>spinner</literal></para></listitem>
          <listitem><para><literal>status_error</literal></para></listitem>
          <listitem><para><literal>status_normal</literal></para></listitem>
          <listitem><para><literal>table_border</literal></para></listitem>
          <listitem><para><literal>tree</literal></para></listitem>
          <listitem><para><literal>unlisted</literal></para></listitem>
        </itemizedlist></para>

        <para>
        Add <literal>_fg</literal> for a foreground color and
        <literal>_bg</literal> for a background colors.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."broot/conf.toml".source =
      tomlFormat.generate "broot-config" brootConf;

    # Dummy file to prevent broot from trying to reinstall itself
    xdg.configFile."broot/launcher/installed-v1".text = "";

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        # This script was automatically generated by the broot function
        # More information can be found in https://github.com/Canop/broot
        # This function starts broot and executes the command
        # it produces, if any.
        # It's needed because some shell commands, like `cd`,
        # have no useful effect if executed in a subshell.
        function br {
            f=$(mktemp)
            (
                set +e
                broot --outcmd "$f" "$@"
                code=$?
                if [ "$code" != 0 ]; then
                    rm -f "$f"
                    exit "$code"
                fi
            )
            code=$?
            if [ "$code" != 0 ]; then
                return "$code"
            fi
            d=$(cat "$f")
            rm -f "$f"
            eval "$d"
        }
      '');

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      # This script was automatically generated by the broot function
      # More information can be found in https://github.com/Canop/broot
      # This function starts broot and executes the command
      # it produces, if any.
      # It's needed because some shell commands, like `cd`,
      # have no useful effect if executed in a subshell.
      function br {
          f=$(mktemp)
          (
              set +e
              broot --outcmd "$f" "$@"
              code=$?
              if [ "$code" != 0 ]; then
                  rm -f "$f"
                  exit "$code"
              fi
          )
          code=$?
          if [ "$code" != 0 ]; then
              return "$code"
          fi
          d=$(cat "$f")
          rm -f "$f"
          eval "$d"
      }
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      # This script was automatically generated by the broot function
      # More information can be found in https://github.com/Canop/broot
      # This function starts broot and executes the command
      # it produces, if any.
      # It's needed because some shell commands, like `cd`,
      # have no useful effect if executed in a subshell.
      function br
          set f (mktemp)
          broot --outcmd $f $argv
          if test $status -ne 0
              rm -f "$f"
              return "$code"
          end
          set d (cat "$f")
          rm -f "$f"
          eval "$d"
      end
    '';
  };
}
