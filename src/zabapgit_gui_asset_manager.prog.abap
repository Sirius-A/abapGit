*&---------------------------------------------------------------------*
*&  Include           ZABAPGIT_GUI_ASSET_MANAGER
*&---------------------------------------------------------------------*

CLASS lcl_gui_asset_manager DEFINITION FINAL CREATE PRIVATE FRIENDS lcl_gui.
  PUBLIC SECTION.

    METHODS get_asset
      IMPORTING iv_asset_name  TYPE string
      RETURNING VALUE(rv_data) TYPE xstring
      RAISING   lcx_exception.

    METHODS get_images
      RETURNING VALUE(rt_images) TYPE tt_web_assets.

  PRIVATE SECTION.

    METHODS get_inline_asset
      IMPORTING iv_asset_name  TYPE string
      RETURNING VALUE(rv_data) TYPE xstring
      RAISING   lcx_exception.

    METHODS get_mime_asset
      IMPORTING iv_asset_name  TYPE c
      RETURNING VALUE(rv_data) TYPE xstring
      RAISING   lcx_exception.

    METHODS get_inline_images
      RETURNING VALUE(rt_images) TYPE tt_web_assets.

ENDCLASS. "lcl_gui_asset_manager

CLASS lcl_gui_asset_manager IMPLEMENTATION.

  METHOD get_asset.

    DATA: lv_asset_name TYPE string,
          lv_mime_name  TYPE wwwdatatab-objid.

    lv_asset_name = to_upper( iv_asset_name ).

    CASE lv_asset_name.
      WHEN 'CSS_COMMON'.
        lv_mime_name = 'ZABAPGIT_CSS_COMMON'.
      WHEN 'JS_COMMON'.
        lv_mime_name = 'ZABAPGIT_JS_COMMON'.
      WHEN OTHERS.
        lcx_exception=>raise( |Improper resource name: { iv_asset_name }| ).
    ENDCASE.

    rv_data = get_mime_asset( lv_mime_name ).
    IF rv_data IS INITIAL. " Fallback to inline asset
      rv_data = get_inline_asset( lv_asset_name ).
    ENDIF.

    IF rv_data IS INITIAL.
      lcx_exception=>raise( |Failed to get GUI resource: { iv_asset_name }| ).
    ENDIF.

  ENDMETHOD.  " get_asset.

  METHOD get_mime_asset.

    DATA: ls_key    TYPE wwwdatatab,
          lv_size_c TYPE wwwparams-value,
          lv_size   TYPE i,
          lt_w3mime TYPE STANDARD TABLE OF w3mime.

    ls_key-relid = 'MI'.
    ls_key-objid = iv_asset_name.

    " Get exact file size
    CALL FUNCTION 'WWWPARAMS_READ'
      EXPORTING
        relid            = ls_key-relid
        objid            = ls_key-objid
        name             = 'filesize'
      IMPORTING
        value            = lv_size_c
      EXCEPTIONS
        entry_not_exists = 1.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    lv_size = lv_size_c.

    " Get binary data
    CALL FUNCTION 'WWWDATA_IMPORT'
      EXPORTING
        key               = ls_key
      TABLES
        mime              = lt_w3mime
      EXCEPTIONS
        wrong_object_type = 1
        import_error      = 2.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_size
      IMPORTING
        buffer       = rv_data
      TABLES
        binary_tab   = lt_w3mime
      EXCEPTIONS
        failed       = 1.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

  ENDMETHOD.  " get_mime_asset.

  METHOD get_images.

    FIELD-SYMBOLS <image> LIKE LINE OF rt_images.

    rt_images = get_inline_images( ).

    " Convert to xstring
    LOOP AT rt_images ASSIGNING <image>.
      CALL FUNCTION 'SSFC_BASE64_DECODE'
        EXPORTING
          b64data = <image>-base64
        IMPORTING
          bindata = <image>-content
        EXCEPTIONS
          OTHERS  = 1.
      ASSERT sy-subrc = 0. " Image data error
    ENDLOOP.

  ENDMETHOD.  " get_images.

  DEFINE _inline.
    APPEND &1 TO lt_data.
  END-OF-DEFINITION.

  METHOD get_inline_asset.

    DATA: lt_data TYPE ty_string_tt,
          lv_str  TYPE string.

    CASE iv_asset_name.
      WHEN 'CSS_COMMON'.
        " @@abapmerge include zabapgit_css_common.w3mi.data.css > _inline '$$'.
      WHEN 'JS_COMMON'.
        " @@abapmerge include zabapgit_js_common.w3mi.data.js > _inline '$$'.
      WHEN OTHERS.
        lcx_exception=>raise( |No inline resource: { iv_asset_name }| ).
    ENDCASE.

    CONCATENATE LINES OF lt_data INTO lv_str SEPARATED BY gc_newline.

    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text      = lv_str
      IMPORTING
        buffer    = rv_data
      EXCEPTIONS
        OTHERS    = 1.
    ASSERT sy-subrc = 0.

  ENDMETHOD.  " get_inline_asset.

  METHOD get_inline_images.

    DATA ls_image TYPE ty_web_asset.

* see https://github.com/larshp/abapGit/issues/201 for source SVG
    ls_image-url     = 'img/logo' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAAKMAAAAoCAYAAACSG0qbAAAABHNCSVQICAgIfAhkiAAA'
      && 'AAlwSFlzAAAEJQAABCUBprHeCQAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9y'
      && 'Z5vuPBoAAA8VSURBVHic7Zx7cJzVeYef31nJAtvYko1JjM3FYHlXimwZkLWyLEMcwIGQ'
      && 'cEkDJWmTltLStGkoDCkzwBAuCemUlksDNCkhJTTTljJpZhIuBQxxAWPvyuYiW7UkG8Il'
      && 'UByIsS1sLEu75+0fu5JXu9/etAJz0TOzM/rOec85765+37m+3yczY8w0NU3qrwv9npfa'
      && 'Hfx02pPPd469sgk+7misYnyjpWXy5IOG7kd8ZjjNjEtr13TdOm7eTfCxwo2lUJAQASRu'
      && '2dnRfMn4uDbBx42yxZhPiMNMCHKCsVK2GGuqqqoQUwrZTAhygrFQshjfaGmZ/M7yxQtm'
      && 'xGL9/qDqzwLxQvYTgpygXEoS4/DQ7LE1O05atLBu1YZdE4KcYLwpupoOmCO+5Z2dXPfE'
      && 'xk07Tm2ZroGhBwX1wAygKqiOiVX2Rw9Jam/gyH0wuGGzvTEudRYSY4HFyogghxN2n7Sw'
      && 'IendvcCioLoOtCCXNeqohOf0oDwPq9f3Wt/77dOHlWhYzUj/BRybTnrGEnZO5wv2m0rq'
      && 'DezJoOiqeZbzegzpk6TVPPWJTT39y5svMogF1ZcesjlQgkwYp4F+EJQXwv4E+MiLUZJa'
      && 'F7AIcRq4hWZ2mMRhQD/oZcErXv7FScaja3rt/wpU9E/sFyLACQq57wB/XIl/gWIstn2T'
      && 'xpHVre7ZW71p8sFDeQscSEHKu3pTBadNH2Lq61VT57iwNazLgaNSqYaUaWXLDZCJIbBo'
      && 'g3tK2A2xHns0oMrm3CRrqdTPnAVMiUIEmLlz2XGLMxNmH7YrifFcoUIHalHj8f8p6UfA'
      && 'O+932weStno1zghps6Q7GBFiUYRxopkeaZ2vIwLyfxtQ4vV8lbWHNScacf+T/vwqn90o'
      && 'MZYhRADJ+bv725vmj6Q8tHWffPKUD6IgO/tsfawneRHYd97Pdg8kSyJaZiGtBY4pYPYO'
      && 'kH84C0Cyv8tKSiK7OZ99EpYAJ2V8AhkRY5lCHGaxhaq+BLCzY/EXd5y0aOG0td1vf1AF'
      && 'CWCw7/1u80DQEtahQvcB03MyjQfM7Hwnmxfv9dPivX5SssqOwuzPSqk71mN3ymw5ZtdK'
      && 'dmVIdly8xx7JZ29yy0qptwrGLMRRCA6T1w93nLTo5Lq13Zv625tOMRd6DLF4v0lWmQO8'
      && 'qPko45y7TWaHZyUnwa6M99mN2fYbuu1V4K5oxF1B4Z4UgFifrQHWFLNbvkh1QheV5DNN'
      && 'TZMqFWIGs5zX48M95PTqGa3TZ4erzbvj8/WUErf0L2++uNyGJLn2Js1oDeuYlkbNbmlR'
      && 'deXup2hq0qS2es2VlHMDFaOlRdXL5uuwlnodG23QTEljCkbJV3d7WHOK+dXWqHqZnZeb'
      && 'Y1fGe3OFOArRU5GTGbSHNWdwUL8Epo1qIQ9V/bXu3HES4jCznNfjb7e1zZ8Ri/UD1MLz'
      && 'u05s/huMx4IKGNy4+8Tj/2Pqk8++Vaji86TQqxEuNNM5rWGtSCaokSDkgd0QjbidoPvN'
      && '+5s7t9jz5TgdbdBMvLsG2cop6FgLUdUaZk804jYKuyrWa6vzlT2+XrOqQnxd6KwQOj5R'
      && 'hULpL9Yaxkcj7g3QT6zK397ZbdtGtbtAZ+B0U3adkt0c67E7OyI6fFDuSpktC6HGpJjU'
      && 'GmZ3NOI2mdnVnX32eHZZ7903hGXfBG8mp3J7sd/B0DPCTgUmBf9O7lmMybk56or3Jn8f'
      && 'oLVB7Q5dZ9Iy4OBsw2jYbUUk96fwQrzHf955iBZzsDA+aL9k1owZ20fNzaY/tfFXwK48'
      && 'ldQkSZ5YqJXmZk15JaJfmOmfgdOAmgCzWrCvyum5aIO+Uor3AIbOx7QV2TeBMPu3vKYA'
      && 'Sw091hbWt4PKRhu0oDqkmND1wAnk3vkOmAN2lRLa2hrWMVm5Tek2R3286YzWiK4eQltk'
      && '9g1gMfsFMhVYKunR1obQddk+SXZqwLe8acMGe7fYb9HZk7wm3utrBmpsqiXsyClHMHK6'
      && '0hLWoRjHBfmLbP9K3bPYjFPIFWLaQeZnlZ8H4JyFflrMwcK4wG63v3/ycZnXOzqalxE0'
      && 'mU7x9rvvVv93oVZqBtzNGGeU7Jbp9pZGzS7ReiVQVyDfmXRda4PaA9p5mBLmWGmmSron'
      && 'M0FytUGGgjPTAi8UIeVk9u1og5YOJ0QbNBOjIac+Y22JPgLQ1WV7Ol+w36xebYnhtGpj'
      && 'FjBYTj3l4KY9/dx6My4d74pN/Ki/Y9HpSG5HR/Nyh/1DHtO9OM6dvWFDwbtWslOykt6U'
      && 's5VWZbOFnQtsyMqvc56Ty3T7NeBhLGAfDZDpe5nX6V5uXpbZ43K2NGQ2V9glwLas/I62'
      && 'hfrE8EWsJ3mFsGYs+OQqze+A1cBLgbmma4f/9AmOJGBe5vKVLYN1W6wnOWSHmdkVhexM'
      && 'PG6yC0x2AbmjoQ3njdh4uwrSw1Htmq5bd3Y0I3FLpQ5n0GTSQ7s6Fva70RPYTPbi+Pz0'
      && 'J7ryboRC+m5PnRfsJjVEAfp5bLNflTb52dKIBj36RWY5ZyX2WCLukvbX67ZYHFLHZtGw'
      && '+1fD/jDL8qQljWpav9m6Uw3wKYzXgUNJTxsk+0Fssw0L6x+j4dCx6eF/BEtwDBkbx7Fe'
      && '29gWCa0yrC2rvXXO26WZfrWG3V2kji8zWbm0QUev67GX5ZgZ8A0H121hXIIZNrxou9oW'
      && '6m4b4m/z2aTP+fsAohF3PaNHROvssZ8ElRs5DnyPBAkovxDFF4oJESDeY9tJD4Ur5umg'
      && 'PSFm1Uy23Zk2SaM7e43p5Y4uxUMzu2f4H56+tuZmff2gfTqHrGEy5DkW6Abo7LH7gfsB'
      && '2uo1LQGzBmoYFSwg57vNcjqqo4F1JXh2S7Zfx83TZZNqdD6MXkQkU369jONgcmfxe83M'
      && 'B7XQEdEhg1B0HzDk2ZHpy3vBqLPpMQhyi/f2AIA3WyPZG6KkeVpKiE925awEi7H6JRsA'
      && 'cqJDfIi9oayfW8ZB5dY/TFeX7YlGQg+RmgJkcnSQfWyr9QP92enmGcgeNCvx67mXbGdb'
      && 'xD1hjI5AklJ+ydgTUGz6iiZNXd09+gYGGIRlQgXn6wDesZYSRFsJOYES5QjSw7fqnu7q'
      && 'Bqh7uqu7f3nzdw3uKFJszEIcpqVRs12SRuAYiTrJ1YXMzSGgS6iQnHmWyQWe70pySz/F'
      && 'MZagMWnMlaiTuTqTTih7s7IIHm1T1ncVI37l3BAAA4McAYF7iAvG17uxExi1U6Igd9XN'
      && 'Dj+UmZA8qPrf3MDQbeSPIN8Ldub0JzeWLcT2I3Swn8JFhr4VQnMze5uKnv0ugOHfUXa3'
      && 'ZhySedkR0eGDuMtbw/rTZCI1pA9PF0yWf4e3MnJ7YKXm0pOr6H03QRIIZeYnUj1njhid'
      && '8aaRscKX/VGWSRLsCjnK2rcdC3njGUsQ5PSdv92yqJaMk5WBoRMpJsSnNgZufBdCkmsN'
      && '60FgRbllK8PNzOlttT/qpz2sOUnpeWGHvq9ewcyc28/7XQCru213NOL+l6wgZ0kXAjnD'
      && 'cazP7gXuTdu41rCyxbgr3mt/P16+F6LgUVXtmq5bC237yNsNu5YtPBZgx4kLFznZ1XlM'
      && 'BzB/1liECBAN801yhfiq0HflbKXz1ojZ4qCylSBsbm6q/93wX0n0Q1Ir6UzWYXaZyZaF'
      && 'qqxeZn813n4ZlhPWJWXMo00P5OTDF5c0qmm8fRlPip6bFhHk6Ti3ddfy5i3OXBemJQE2'
      && 'A5g/c/qaTasC8krC0KdzE+3qWG/y6thmW7Vui/UkQ7w51vqDaGnRZFInPdlshNQ2C8oJ'
      && 'h0oqaefF++zmzh5bu7bbXrBxjp88bp5qgZzNdyfWD/9t+B+TO4GW8/p+R0SHcGBxLWEF'
      && 'jiQlHeIXEaRIPZAVRMVCTDcQCUh8LfOyaqjgCcr+YpY7NRFa2VY/egsqtNtdw8ie5gjJ'
      && 'oUTqicjofOYA2f/YgcR03s5MMBF4wlIa7rMr5mnUyru6xl0LZAeFvDG3l83DF5199muk'
      && 'oJO1FUMoviSi8Nh9Kg+Ru7qvUvCqPO+cMZsxbPsM4HXW9KcrEyKApTa7s9BVSyLaF3Ik'
      && 'SbLSQros18RyInkkV2u5q+6zLaS+aCT0oJl/QVI78IWcsvDos1vtLYCE551QKNuCKW63'
      && '+157g36cMOYI9yWhC3K+j4KDEHKxC9+t0altDaFHwL/kvVZIBJw761/uM5/MTJlU7S/Z'
      && 'N6hTBNlhZA0OPReNuGdM6nL4jR4G5ZnRusAtKmVHwg1Slcxe11nODZJKh1fJ6kwM3dQa'
      && 'VgOw3omjkGuL9/o/L/vFTzs7mi8pQZBpIT4f9PxE2bRFQncY9pdjKDoExDH7ebzPbgFo'
      && 'bQjdng48KBfvzZau77ORN61FI66PsW2N7ARiZnZTZ589BtAWCV1v5J1zF+JNVdui2CbL'
      && 'OcJsq1ejD2lVgCDL4e14r58J0N6k+cmEu0HYIssdrbxgnaGeeG9yJEg32hC6GbOix81y'
      && 'trTsWLtiixpgQNLZ4yVEgCT++xSP0H7C0N1ZadVAh6SR3kRm2WfJO0H/XqTuQcn+IlOI'
      && 'AFjRVaZhus3g2az0WuA0wcIi5QP3DDNIIPtakBABYltts7AO4OEi9eTFYGCksSRzwM4L'
      && 'ECKAM1gG9tVR5UP+RkqZN5s7a0yBnwUEOSDp7GlPPp83BH0srO+1PmQrDIIen9wOdnln'
      && 'n31G5n9ZtDLL6ck2x3uTf6DUee8rASX6vNnyWI/dmZ0R77O7LNXLBkWy9CE7Pd6XvNih'
      && 'QkEQeZHZl9PBFtsDstebtyWFwv0B4r32UrzXn+6xDtBdwIslNL0N+JnMvravxiraFO/s'
      && 'tm0y+xzQlcfkddCNCe/vGfP7GQH6lzdfbHAjqSCBHZK+PN5CzESSlixgnhMLzXAeXp+3'
      && 'hWfuM0sWL10abQv1CdtHixzvmtiYPhcvSFOTJk1NEPEQkWdPUry4oc96y2o3YJiWs5Wx'
      && 'zbYq83THHHu9Y1N2kG45tDRqdsgzxxuznKPOGbsTsN2M7d6zfXhePJ5Ici1h6mUcAcw0'
      && '8Zo5fp35NoqKxAjwTrRhZmLSpPY9ySmPzV27dm+lTn9cKSTGA+XT+03Jq+l8HBLv2Q7c'
      && 'X9K+ygQTFGDcHhaaoGJyouDNV7JH+eGj4mF6gspoC+tzJt1ObsT4MDsF2zxs886+Ml5v'
      && '/PogUvEwPUGFiE+SX4gAtQa1gkhV7onQR4oJMR5oxC6stDeghd7Dh6E+CPw/HL4vVO2f'
      && 'cpUAAAAASUVORK5CYII='.
    APPEND ls_image TO rt_images.

* http://fa2png.io/r/octicons/
* colour: #808080
* size: 16
* https://www.base64-image.de/ can be used to convert images to base64

    ls_image-url     = 'img/sync' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAQAAAC1+jfqAAAA6ElEQVQYGY3BIWuUAQAG'
      && '4Pc7N72xsbGBYNE8tYpVZKDZX2CcYLEZ9yQxOQSz3D/YmkUsVovRQ2SYNJnlkFfH7VZu'
      && 'wefJgrGHXnjrpQeu5B93smCwr6qqqp54433mDI5Ucds1u577o+p35hyoqe2cMThWVatJ'
      && '7KiZrZxz18SJqqtJPFXPssRgw0oSH9WNXMCQU76qzSxx2cxxTlk3yhKb6mcSQy7kvjpM'
      && 'Ylt98tpjN3POyFTdSuKSqppayxkjE/Uhc36p+m7PhhXr7vmmfhhnzpHPJqqqquqdcRY8'
      && 'spq47sAXMyde2c3/+wvX7Y18BexhBwAAAABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/toc' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQBAMAAADt3eJSAAAAFVBMVEUAAACAgICAgICA'
      && 'gICAgICAgICAgIAO39T0AAAABnRSTlMABBCRlMXJzV0oAAAAN0lEQVQIW2NgwABuaWlB'
      && 'YWlpDgwJDAxiAgxACshgYwAz0tLY2NISSBWBMYAmg4ADyBZhARCJAQBBchGypGCbQgAA'
      && 'AABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/repo_online' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAApVBMVEUAAABQbJxQbJxQ'
      && 'bJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQ'
      && 'bJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQ'
      && 'bJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQbJxQ'
      && 'bJz+TJ01AAAANnRSTlMAAQIDBAcJCgwSFBocHygqMTM1NkRHSU1QUWFiZGlweHuDiImL'
      && 'lZiio6a5vsfT3uTo6e3x9fsxY2JuAAAAgUlEQVQYGXXB6RaBUBSA0e+IEuIiMs9zhlDn'
      && '/R/NZWmt/LA3f1RcoaB50SydCbn20wjedkPu3sKSpMGH21PhLdZ0BATZ+cCXtxtDHGLV'
      && 'pgFW9QqJj2U0wvJvMF+5jiNGI3HK9dMQSouH6sRoFGoWd8l1dEDRWlWPQsFS98KPvvDH'
      && 'C3HLClrWc70ZAAAAAElFTkSuQmCC'.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/repo_offline' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAVFBMVEUAAACAgICAgICA'
      && 'gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA'
      && 'gICAgICAgICAgICAgICAgICAgICAgICuaWnmAAAAG3RSTlMAAgQFBgsQFxweIiMtN3yI'
      && 'nqOvt9Hp6/Hz9fktMNR/AAAAXElEQVQYV5WO2xJAMAxES1q3ugfF/v9/0qLyyL4k58xk'
      && 'J0p9D7N5oeqZgSwy7fDZnHNdEE1gWK116tksl7hPimGFFPWYl7MU0zksRCl8TStKg1AJ'
      && '0XNC8Zm4/c0BUVQHi0llOUYAAAAASUVORK5CYII='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/pkg' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAQAAAC1+jfqAAAA30lEQVQoU43OIUuDcRSF'
      && '8fvqhuB0mFwaKLbVBVdkX0GTFss+wYL2H4rJIIgyQQSzZcUPoGHZ9CKCmAwTMS8Y/ga3'
      && 'BWVjT7hwOQ+HEzEbMhU7jrTd69q2KhtFRU2nrvS927dm3pyqPXcuNRVD7sxiRIQlDSc+'
      && 'PGjZUFDWkYekLfdoV2XYua4rSZ61pZBkEUq2XPty41XuXJIiZGNhPDVZiFCYIMSor+Db'
      && '7RQhYnQnCsNvNmGgPFFYMQh1PU9aqrLxyGUNx/p66r9mUc2hFx3JhU9vDtQU4y9KGjaV'
      && '/gXT+AGZVIinhU2EAwAAAABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/branch' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAqFBMVEUAAACAgICAgICA'
      && 'gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA'
      && 'gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA'
      && 'gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA'
      && 'gICAgID/OyosAAAAN3RSTlMAAQIDBAYICQ8TFRweJScoKSo3Oj1FRk1dYWJjZmhzdIaJ'
      && 'j5GVm6CwsrS5vsHDyszV19ne7/X583teZAAAAIFJREFUGFdVytkagVAYheFvFzJlnqc0'
      && 'EEoR+u//zhxI7dbZ9z4LMJ1op9DmjpntdXiBigHbLiAYqukBVr63+YGRSazgCY/iEooP'
      && 'xKZxr0EnSbo14B1Rg4msKzj150fJrQpERPLBv7mIfNxlq+zRbZsu0JYpGlcdwjY9Twfr'
      && 'nAbNsr6IKQxJI/U5CgAAAABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/link' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAXVBMVEUAAACAgICAgICA'
      && 'gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA'
      && 'gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICVwFMKAAAAHnRSTlMAAwQFBgcK'
      && 'FR4gIiMmP0JHSm+RmKDByM/R09rg+/0jN/q+AAAAX0lEQVQYV43Nxw6AIBAE0FGw916Z'
      && '//9MRQ0S4sG5bPZlCxqSCyBGXgFUJKUA4A8PUOKONzuQOxOZIjcLkrMvxGQg3skSCFYL'
      && 'Kl1Ds5LWz+33yyf4rQOSf6CjnV6rHeAA87gJtKzI8ocAAAAASUVORK5CYII='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/code' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOBAMAAADtZjDiAAAAElBMVEUAAACAgICAgICA'
      && 'gICAgICAgIC07w1vAAAABXRSTlMABECUxcOwZQcAAAA1SURBVAhbY2AODQ0NEWBgYGVg'
      && 'YGByhNAMKgIMrKyhAQxMDhA+QwCCZgVqIIUP1Q+yJzTUAAAfUAq+Os55uAAAAABJRU5E'
      && 'rkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/bin' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOBAMAAADtZjDiAAAAElBMVEUAAACAgICAgICA'
      && 'gICAgICAgIC07w1vAAAABXRSTlMABECUxcOwZQcAAABBSURBVAhbXcqxDYAwAMRAK8h9'
      && 'hmAARoANvuD3X4UCiojqZMlsbe8JAuN6ZZ9ozThRCVmsJe9H0HwdXf19W9v2eAA6Fws2'
      && 'RotPsQAAAABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/obj' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOBAMAAADtZjDiAAAAIVBMVEUAAACAgICAgICA'
      && 'gICAgICAgICAgICAgICAgICAgICAgIDcWqnoAAAACnRSTlMABD1AZI+RlcPFIaFe1gAA'
      && 'AEVJREFUCFtjYF+1atVKAQYGLgYGBuaJEJrBUgBCM0+A0AwLgLQIgyOIZmwCSgNptgAG'
      && '1gQQfzKDhgCSPFw9Kg2yZ9WqAgBWJBENLk6V3AAAAABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/lock' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAOVBMVEUAAACIiIiIiIiI'
      && 'iIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIjNaTNB'
      && 'AAAAEnRSTlMABgdBVXt8iYuRsNXZ3uDi6Pmu6tfUAAAASUlEQVQYV63KSxJAQBAE0TQ0'
      && 'Znym1f0PayE0QdjJ5asCgGTu1hClqjppvaRXB60swBeA2QNUAIq+ICvKx367nqAn/P8Y'
      && 't2jg3Q5rgASaF3KNRwAAAABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/dir' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAASFBMVEUAAABmksxmksxm'
      && 'ksxmksxmksxmksxmksxmksxmksxmksxmksxmksxmksxmksxmksxmksxmksxmksxmksxm'
      && 'ksxmksxmksxmksxMwQo8AAAAF3RSTlMABhIYIy1fZmhpe3+IiYuMkZvD7e/x93sipD4A'
      && 'AAA+SURBVBhXY2BABzwiokAgzAYXEGdiBAIWIYQAPzcQCApzgwEXM4M4KuBDFxAYKAEx'
      && 'VAFeBlYOTiTAzoThewD5hBAcnWM4gwAAAABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/burger' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQBAMAAADt3eJSAAAAHlBMVEUAAABtktltktlt'
      && 'ktltktltktltktltktltktltktk7ccVDAAAACXRSTlMAFDBLY2SFoPGv/DFMAAAAJ0lE'
      && 'QVQIW2NggIHKmWAwmaETwpjGoBoKBo4MmIAkxXApuGK4dgwAAJa5IzLs+gRBAAAAAElF'
      && 'TkSuQmCC'.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/star' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAilBMVEUAAABejclejcle'
      && 'jclejclejclejclejclejclejclejclejclejclejclejclejclejclejclejclejcle'
      && 'jclejclejclejclejclejclejclejclejclejclejclejclejclejclejclejclejcle'
      && 'jclejclejclejclejclejclejclejclejcn2yvsVAAAALXRSTlMAAQIFBwkKCw0QERUY'
      && 'HB4jLzEzNjg7PVdYYmRvd3mDm52eub7R0+Tr8fX3+/16wo8zAAAAcElEQVQYGW3BBxKC'
      && 'MABFwYcQETv2hg1UVP79ryeTZBxw3MWL+JGltBgVtGRSSoORVOAE8Xi5zVU7rWfDCOaV'
      && 'Gu59mLz0dTPUBg95eYjVK2VdOzjBW9YZL5FT4i2k5+YoKcY5VPsQkoumOLsu1mjFHx8o'
      && 'ahA3YV7OfwAAAABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.

    ls_image-url     = 'img/star-grey' ##NO_TEXT.
    ls_image-base64 =
         'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAMAAAAoLQ9TAAAAilBMVEUAAADQ0NDQ0NDQ'
      && '0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ'
      && '0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ'
      && '0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NC2QdifAAAALXRSTlMAAQIFBwkKCw0QERUY'
      && 'HB4jLzEzNjg7PVdYYmRvd3mDm52eub7R0+Tr8fX3+/16wo8zAAAAcElEQVQYGW3BBxKC'
      && 'MABFwYcQETv2hg1UVP79ryeTZBxw3MWL+JGltBgVtGRSSoORVOAE8Xi5zVU7rWfDCOaV'
      && 'Gu59mLz0dTPUBg95eYjVK2VdOzjBW9YZL5FT4i2k5+YoKcY5VPsQkoumOLsu1mjFHx8o'
      && 'ahA3YV7OfwAAAABJRU5ErkJggg=='.
    APPEND ls_image TO rt_images.


  ENDMETHOD.  " get_inline_images.

ENDCLASS. "lcl_gui_asset_manager