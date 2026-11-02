#ifndef RUNNER_ACCESSIBILITY_ALERT_H_
#define RUNNER_ACCESSIBILITY_ALERT_H_

#include <oleacc.h>
#include <windows.h>
#include <wrl/implements.h>

#include <string>
#include <utility>

// A single MSAA alert. Flutter's announce path also raises a UIA alert, which
// Narrator can speak a second time. This provider sends only one WinEvent.
class AccessibilityAlert final
    : public Microsoft::WRL::RuntimeClass<
          Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>,
          IAccessible> {
 public:
  explicit AccessibilityAlert(HWND window) : window_(window) {}
  void Announce(std::wstring text) {
    text_ = std::move(text);
    NotifyWinEvent(EVENT_SYSTEM_ALERT, window_, OBJID_ALERT, CHILDID_SELF);
  }
  HRESULT STDMETHODCALLTYPE GetTypeInfoCount(UINT* count) override {
    if (!count) return E_POINTER;
    *count = 0;
    return S_OK;
  }
  HRESULT STDMETHODCALLTYPE GetTypeInfo(UINT, LCID, ITypeInfo**) override {
    return E_NOTIMPL;
  }
  HRESULT STDMETHODCALLTYPE GetIDsOfNames(REFIID, LPOLESTR*, UINT, LCID,
                                          DISPID*) override {
    return E_NOTIMPL;
  }
  HRESULT STDMETHODCALLTYPE Invoke(DISPID, REFIID, LCID, WORD, DISPPARAMS*,
                                   VARIANT*, EXCEPINFO*, UINT*) override {
    return E_NOTIMPL;
  }
  HRESULT STDMETHODCALLTYPE get_accParent(IDispatch** parent) override {
    return AccessibleObjectFromWindow(window_, OBJID_WINDOW, IID_IDispatch,
                                      reinterpret_cast<void**>(parent));
  }
  HRESULT STDMETHODCALLTYPE get_accChildCount(long* count) override {
    if (!count) return E_POINTER;
    *count = 0;
    return S_OK;
  }
  HRESULT STDMETHODCALLTYPE get_accChild(VARIANT, IDispatch** child) override {
    if (!child) return E_POINTER;
    *child = nullptr;
    return S_FALSE;
  }
  HRESULT STDMETHODCALLTYPE get_accName(VARIANT, BSTR* name) override {
    if (!name) return E_POINTER;
    *name = SysAllocString(text_.c_str());
    return *name ? S_OK : E_OUTOFMEMORY;
  }
  HRESULT STDMETHODCALLTYPE get_accValue(VARIANT, BSTR* output) override {
    return EmptyString(output);
  }
  HRESULT STDMETHODCALLTYPE get_accDescription(VARIANT, BSTR* output) override {
    return EmptyString(output);
  }
  HRESULT STDMETHODCALLTYPE get_accRole(VARIANT, VARIANT* role) override {
    if (!role) return E_POINTER;
    VariantInit(role);
    role->vt = VT_I4;
    role->lVal = ROLE_SYSTEM_ALERT;
    return S_OK;
  }
  HRESULT STDMETHODCALLTYPE get_accState(VARIANT, VARIANT* state) override {
    if (!state) return E_POINTER;
    VariantInit(state);
    state->vt = VT_I4;
    state->lVal = 0;
    return S_OK;
  }
  HRESULT STDMETHODCALLTYPE get_accHelp(VARIANT, BSTR* output) override {
    return EmptyString(output);
  }
  HRESULT STDMETHODCALLTYPE get_accHelpTopic(BSTR*, VARIANT, long*) override {
    return E_NOTIMPL;
  }
  HRESULT STDMETHODCALLTYPE get_accKeyboardShortcut(VARIANT,
                                                    BSTR* output) override {
    return EmptyString(output);
  }
  HRESULT STDMETHODCALLTYPE get_accFocus(VARIANT* output) override {
    return EmptyVariant(output);
  }
  HRESULT STDMETHODCALLTYPE get_accSelection(VARIANT* output) override {
    return EmptyVariant(output);
  }
  HRESULT STDMETHODCALLTYPE get_accDefaultAction(VARIANT,
                                                 BSTR* output) override {
    return EmptyString(output);
  }
  HRESULT STDMETHODCALLTYPE accSelect(long, VARIANT) override {
    return E_NOTIMPL;
  }
  HRESULT STDMETHODCALLTYPE accLocation(long* x, long* y, long* width,
                                        long* height, VARIANT) override {
    if (!x || !y || !width || !height) return E_POINTER;
    RECT bounds{};
    if (!GetWindowRect(window_, &bounds)) return E_FAIL;
    *x = bounds.left;
    *y = bounds.top;
    *width = bounds.right - bounds.left;
    *height = bounds.bottom - bounds.top;
    return S_OK;
  }
  HRESULT STDMETHODCALLTYPE accNavigate(long, VARIANT,
                                        VARIANT* output) override {
    return EmptyVariant(output);
  }
  HRESULT STDMETHODCALLTYPE accHitTest(long, long, VARIANT* output) override {
    return EmptyVariant(output);
  }
  HRESULT STDMETHODCALLTYPE accDoDefaultAction(VARIANT) override {
    return E_NOTIMPL;
  }
  HRESULT STDMETHODCALLTYPE put_accName(VARIANT, BSTR) override {
    return E_NOTIMPL;
  }
  HRESULT STDMETHODCALLTYPE put_accValue(VARIANT, BSTR) override {
    return E_NOTIMPL;
  }

 private:
  static HRESULT EmptyString(BSTR* output) {
    if (!output) return E_POINTER;
    *output = nullptr;
    return S_FALSE;
  }
  static HRESULT EmptyVariant(VARIANT* output) {
    if (!output) return E_POINTER;
    VariantInit(output);
    return S_FALSE;
  }
  HWND window_;
  std::wstring text_;
};

#endif
