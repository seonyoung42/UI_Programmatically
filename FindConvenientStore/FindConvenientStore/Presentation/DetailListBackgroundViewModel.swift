//
//  DetailListBackgroundViewModel.swift
//  FindConvenientStore
//
//  Created by 장선영 on 2022/03/10.
//

import RxSwift
import RxCocoa

struct DetailListBackgroundViewModel {
    // viewModel - view
    let isStatusLabelHidden: Signal<Bool>
    
    // 외부에서 전달받을 값
    let shouldHideStatusLabel = PublishSubject<Bool>()
    
    init() {
        isStatusLabelHidden = shouldHideStatusLabel
            .asSignal(onErrorJustReturn: true)
    }
}
